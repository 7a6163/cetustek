# frozen_string_literal: true

require 'ox'
require 'cgi'

module Cetustek
  module Services
    class InvoiceXmlBuilder
      def initialize(invoice_data)
        @data = invoice_data
      end

      def build
        doc = Ox::Document.new
        doc << create_xml_instruct
        doc << create_invoice_element

        Ox.dump(doc)
      end

      private

      def create_xml_instruct
        instruct = Ox::Instruct.new(:xml)
        instruct[:version] = '1.0'
        instruct[:encoding] = 'UTF-8'
        instruct
      end

      def create_invoice_element
        invoice = Ox::Element.new('Invoice')
        invoice[:XSDVersion] = '2.8'

        add_basic_info(invoice)
        add_buyer_info(invoice)
        add_invoice_type_info(invoice)
        add_details(invoice)

        invoice
      end

      def add_basic_info(invoice)
        invoice << Ox::Raw.new("<OrderId>#{@data.order_id}</OrderId>")
        invoice << Ox::Raw.new("<OrderDate>#{@data.order_date.strftime('%Y/%m/%d')}</OrderDate>")
      end

      def add_buyer_info(invoice)
        invoice << Ox::Raw.new("<BuyerIdentifier>#{@data.buyer_identifier}</BuyerIdentifier>")
        invoice << Ox::Raw.new("<BuyerName>#{CGI.escapeHTML(@data.buyer_name)}</BuyerName>")
        invoice << Ox::Raw.new("<BuyerEmailAddress>#{@data.buyer_email}</BuyerEmailAddress>")
      end

      def add_invoice_type_info(invoice)
        invoice << Ox::Raw.new("<DonateMark>#{@data.donate_mark}</DonateMark>")
        invoice << Ox::Raw.new('<InvoiceType>07</InvoiceType>')
        invoice << Ox::Raw.new("<CarrierType>#{@data.carrier_type}</CarrierType>")
        invoice << Ox::Raw.new("<CarrierId1>#{@data.carrier_id}</CarrierId1>")
        invoice << Ox::Raw.new("<CarrierId2>#{@data.carrier_id2}</CarrierId2>")
        invoice << Ox::Raw.new("<NPOBAN>#{@data.npo_ban}</NPOBAN>")
        invoice << Ox::Raw.new('<TaxType>1</TaxType>')
        invoice << Ox::Raw.new("<PayWay>#{@data.payment_type}</PayWay>")
      end

      def add_details(invoice)
        details = Ox::Element.new('Details')
        invoice << details

        @data.items.each do |item|
          details << create_product_item(item)
        end

        add_additional_items(details)
      end

      def create_product_item(item)
        product = Ox::Element.new('ProductItem')
        product << Ox::Raw.new("<ProductionCode>#{item.code}</ProductionCode>")
        product << Ox::Raw.new("<Description>#{CGI.escapeHTML(item.name)}</Description>")
        product << Ox::Raw.new("<Quantity>#{item.quantity}</Quantity>")
        product << Ox::Raw.new("<UnitPrice>#{item.unit_price}</UnitPrice>")
        product
      end

      def add_additional_items(details)
        add_discount_item(details) if @data.total_discount.positive?
        add_coupon_item(details) if @data.coupon_discount.positive?
        add_delivery_fee_item(details) if @data.delivery_fee.positive?
        add_handling_fee_item(details) if @data.handling_fee.positive?
      end

      def add_discount_item(details)
        discount = Ox::Element.new('ProductItem')
        discount << Ox::Raw.new('<ProductionCode>DISCOUNT</ProductionCode>')
        discount << Ox::Raw.new('<Description>折抵金額</Description>')
        discount << Ox::Raw.new('<Quantity>1</Quantity>')
        discount << Ox::Raw.new("<UnitPrice>#{@data.total_discount * -1}</UnitPrice>")
        details << discount
      end

      def add_coupon_item(details)
        coupon = Ox::Element.new('ProductItem')
        coupon << Ox::Raw.new('<ProductionCode>COUPON</ProductionCode>')
        coupon << Ox::Raw.new('<Description>分享折讓</Description>')
        coupon << Ox::Raw.new('<Quantity>1</Quantity>')
        coupon << Ox::Raw.new("<UnitPrice>#{@data.coupon_discount * -1}</UnitPrice>")
        details << coupon
      end

      def add_delivery_fee_item(details)
        delivery = Ox::Element.new('ProductItem')
        delivery << Ox::Raw.new('<ProductionCode>DELIVERY_FEE</ProductionCode>')
        delivery << Ox::Raw.new('<Description>運費</Description>')
        delivery << Ox::Raw.new('<Quantity>1</Quantity>')
        delivery << Ox::Raw.new("<UnitPrice>#{@data.delivery_fee}</UnitPrice>")
        details << delivery
      end

      def add_handling_fee_item(details)
        handling = Ox::Element.new('ProductItem')
        handling << Ox::Raw.new('<ProductionCode>HANDLING_FEE</ProductionCode>')
        handling << Ox::Raw.new('<Description>手續費</Description>')
        handling << Ox::Raw.new('<Quantity>1</Quantity>')
        handling << Ox::Raw.new("<UnitPrice>#{@data.handling_fee}</UnitPrice>")
        details << handling
      end
    end
  end
end
