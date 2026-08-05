# frozen_string_literal: true

require_relative 'invoice_data'

module Cetustek
  module Models
    # Request data for CreateAllowance (開立折讓單), spec AVM-26-03 Table 15/16.
    # Line items reuse InvoiceItem (code/name/quantity/unit/unit_price).
    class AllowanceData
      # 折讓單稅別只有應稅/零稅率/免稅，發票的 4 (特種稅率)、5 (經海關出口)
      # 與 9 (混合) 在折讓單無效。
      TAX_TYPES = [TaxType::TAXABLE, TaxType::ZERO_RATE, TaxType::TAX_FREE].freeze
      MAX_REASON_LENGTH = 20
      ROUND_NUMS = (0..7).freeze

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
        validate!
      end

      private

      def validate!
        missing = { allowance_number: @allowance_number, invoice_number: @invoice_number,
                    invoice_year: @invoice_year, reason: @reason }.select { |_k, v| blank?(v) }.keys
        raise ArgumentError, "#{missing.join(', ')} required" if missing.any?

        validate_allowance_date!
        validate_tax_type!
        validate_reason!
        validate_round_num!
        raise ArgumentError, 'items must not be empty (沒有產品明細)' if @items.empty?
      end

      def validate_allowance_date!
        raise ArgumentError, 'allowance_date is required' if @allowance_date.nil?
        return if @allowance_date.respond_to?(:strftime)

        raise ArgumentError, "allowance_date must be a Date or Time, got #{@allowance_date.class}"
      end

      def validate_tax_type!
        return if TAX_TYPES.include?(@tax_type.to_i)

        raise ArgumentError, "tax_type must be 1 (應稅), 2 (零稅率) or 3 (免稅), got #{@tax_type.inspect}"
      end

      def validate_reason!
        return if @reason.to_s.length <= MAX_REASON_LENGTH

        raise ArgumentError, "reason must not exceed #{MAX_REASON_LENGTH} characters"
      end

      def validate_round_num!
        return if @round_num.nil? || ROUND_NUMS.include?(@round_num.to_i)

        raise ArgumentError, "round_num must be between #{ROUND_NUMS.first} and #{ROUND_NUMS.last}, " \
                             "got #{@round_num.inspect}"
      end

      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end
    end
  end
end
