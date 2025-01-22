# frozen_string_literal: true

require_relative "cetustek/version"
require_relative "cetustek/configuration"
require_relative "cetustek/create_invoice"
require_relative "cetustek/cancel_invoice"
require_relative "cetustek/query_invoice_by_order_id"

module Cetustek
  class Error < StandardError; end

  class << self
    def configure
      yield(config)
    end

    def config
      @config ||= Configuration.new
    end
  end
end
