# frozen_string_literal: true

require 'savon'

module Cetustek
  # Shared SOAP plumbing: every operation hits the same WSDL and authenticates
  # with 網站代碼+APIPassword (source) and the 租賃者統編 (rentid).
  module Soap
    TIMEOUT = 300

    def soap_client
      return httpi_client unless Cetustek.config.transport == :faraday

      faraday_client
    end

    def httpi_client
      Savon.client(wsdl: Cetustek.config.url, open_timeout: TIMEOUT, read_timeout: TIMEOUT)
    end

    # savon 2.17 的 FaradayMigrationHint::OPTIONS 會讓 open_timeout/read_timeout
    # 在 transport: :faraday 下直接 raise，逾時改由 faraday 連線自己設。
    def faraday_client
      require 'faraday'
      Savon.client(wsdl: Cetustek.config.url, transport: :faraday).tap do |client|
        client.faraday.options.open_timeout = TIMEOUT
        client.faraday.options.read_timeout = TIMEOUT
      end
    end

    def source
      Cetustek.config.site_id + Cetustek.config.password
    end

    def rentid
      Cetustek.config.username
    end

    def soap_call(operation, message)
      soap_client.call(operation, message: message.merge(source: source, rentid: rentid))
    end

    def soap_return(response, operation)
      response.body[:"#{operation}_response"][:return]
    end
  end
end
