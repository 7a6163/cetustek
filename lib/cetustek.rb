# frozen_string_literal: true

require_relative "cetustek/version"
require_relative "cetustek/configuration"
require_relative "cetustek/models/allowance_data"
require_relative "cetustek/create_invoice"
require_relative "cetustek/cancel_invoice"
require_relative "cetustek/query_invoice_by_order_id"
require_relative "cetustek/queries"
require_relative "cetustek/create_allowance"
require_relative "cetustek/cancel_allowance"
require_relative "cetustek/phone_barcode"

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
