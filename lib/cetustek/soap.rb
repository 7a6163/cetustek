# frozen_string_literal: true

require 'savon'

module Cetustek
  # Shared SOAP plumbing: every operation hits the same WSDL and authenticates
  # with 網站代碼+APIPassword (source) and the 租賃者統編 (rentid).
  module Soap
    def soap_client
      Savon.client(wsdl: Cetustek.config.url, open_timeout: 300, read_timeout: 300)
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
