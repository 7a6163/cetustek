# frozen_string_literal: true

module Cetustek
  class Configuration
    # HTTPI (savon 的預設) 第一順位是 httpclient，而 httpclient 只認 gem 內附的
    # cacert.pem，裡面沒有 Certum Trusted Root CA — 也就是 sandbox 端點
    # invoice.cetustek.com.tw 憑證鏈的根。只要環境裡有 httpclient，沙盒開票就會
    # 全數 certificate verify failed。改用 :faraday 走 net_http，讀系統信任庫。
    TRANSPORTS = %i[httpi faraday].freeze

    # logger is opt-in: nil means this gem writes nothing anywhere.
    attr_accessor :environment, :site_id, :username, :password, :logger
    attr_reader :transport

    def initialize
      @environment = :sandbox
      @transport = :httpi
    end

    def transport=(value)
      raise ArgumentError, "transport must be one of #{TRANSPORTS.join(', ')}, got #{value.inspect}" \
        unless TRANSPORTS.include?(value)

      @transport = value
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
