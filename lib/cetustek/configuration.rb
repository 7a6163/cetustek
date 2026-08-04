# frozen_string_literal: true

module Cetustek
  class Configuration
    # logger is opt-in: nil means this gem writes nothing anywhere.
    attr_accessor :environment, :site_id, :username, :password, :logger

    def initialize
      @environment = :sandbox
    end

    def url
      if @environment == :production
        'https://www.ei.com.tw/InvoiceMultiWeb/InvoiceAPI?wsdl'
      else
        'https://invoice.cetustek.com.tw/InvoiceMultiWeb/InvoiceAPI?wsdl'
      end
    end

    def production?
      @environment == :production
    end

    def sandbox?
      @environment == :sandbox
    end
  end

  class << self
    def configure
      yield(config)
    end

    def config
      @config ||= Configuration.new
    end
  end
end
