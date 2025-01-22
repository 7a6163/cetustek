# frozen_string_literal: true

module Cetustek
  module Models
    class InvoiceData
      attr_reader :order_id, :order_date, :buyer_identifier, :buyer_name,
                 :buyer_email, :donate_mark, :carrier_type, :carrier_id,
                 :npo_ban, :items, :payment_type, :total_discount,
                 :coupon_discount, :delivery_fee, :handling_fee

      def initialize(attributes = {})
        @order_id = attributes[:order_id]
        @order_date = attributes[:order_date]
        @buyer_identifier = attributes[:buyer_identifier]
        @buyer_name = attributes[:buyer_name]
        @buyer_email = attributes[:buyer_email]
        @donate_mark = attributes[:donate_mark]
        @carrier_type = attributes[:carrier_type]
        @carrier_id = attributes[:carrier_id]
        @npo_ban = attributes[:npo_ban]
        @items = attributes[:items] || []
        @payment_type = attributes[:payment_type]
        @total_discount = attributes[:total_discount] || 0
        @coupon_discount = attributes[:coupon_discount] || 0
        @delivery_fee = attributes[:delivery_fee] || 0
        @handling_fee = attributes[:handling_fee] || 0
      end
    end

    class InvoiceItem
      attr_reader :code, :name, :quantity, :unit_price

      def initialize(attributes = {})
        @code = attributes[:code]
        @name = attributes[:name]
        @quantity = attributes[:quantity]
        @unit_price = attributes[:unit_price]
      end
    end
  end
end
