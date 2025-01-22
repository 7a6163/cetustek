# frozen_string_literal: true

module Cetustek
  class Configuration
    attr_accessor :environment, :site_id, :username, :password

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
