# frozen_string_literal: true

require_relative 'invoice_data'

module Cetustek
  module Models
    # Request data for CreateAllowance (開立折讓單), spec AVM-26-03 Table 15/16.
    # Line items reuse InvoiceItem (code/name/quantity/unit/unit_price).
    class AllowanceData
      attr_reader :allowance_number, :allowance_date, :invoice_number,
                  :invoice_year, :buyer_address, :buyer_email, :tax_type,
                  :reason, :round_num, :items

      def initialize(attributes = {})
        @allowance_number = attributes[:allowance_number]
        @allowance_date = attributes[:allowance_date]
        @invoice_number = attributes[:invoice_number]
        @invoice_year = attributes[:invoice_year]
        @buyer_address = attributes[:buyer_address]
        @buyer_email = attributes[:buyer_email]
        @tax_type = attributes[:tax_type] || TaxType::TAXABLE
        @reason = attributes[:reason]
        @round_num = attributes[:round_num] # optional 金額計算位數
        @items = attributes[:items] || []
      end
    end
  end
end
