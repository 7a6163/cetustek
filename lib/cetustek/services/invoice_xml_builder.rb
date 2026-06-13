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

      # Builds a raw XML element with the value HTML-escaped, so that special
      # characters (&, <, >, ", ') in any dynamic field cannot break the XML
      # or be used for injection.
      def raw_tag(name, value)
        Ox::Raw.new("<#{name}>#{CGI.escapeHTML(value.to_s)}</#{name}>")
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
        invoice << raw_tag('OrderId', @data.order_id)
        invoice << raw_tag('OrderDate', @data.order_date.strftime('%Y/%m/%d'))
      end

      def add_buyer_info(invoice)
        invoice << raw_tag('BuyerIdentifier', @data.buyer_identifier)
        invoice << raw_tag('BuyerName', @data.buyer_name)
        invoice << raw_tag('BuyerEmailAddress', @data.buyer_email)
      end

      def add_invoice_type_info(invoice)
        invoice << raw_tag('DonateMark', @data.donate_mark)
        invoice << raw_tag('InvoiceType', @data.invoice_type)
        invoice << raw_tag('CarrierType', @data.carrier_type)
        invoice << raw_tag('CarrierId1', @data.carrier_id)
        invoice << raw_tag('CarrierId2', @data.carrier_id2)
        invoice << raw_tag('NPOBAN', @data.npo_ban)
        invoice << raw_tag('TaxType', @data.tax_type)
        invoice << raw_tag('TaxRate', @data.tax_rate)
        invoice << raw_tag('PayWay', @data.payment_type)
      end

      def add_details(invoice)
        details = Ox::Element.new('Details')
        invoice << details

        @data.items.each do |item|
          details << create_product_item(item)
        end
      end

      def create_product_item(item)
        product = Ox::Element.new('ProductItem')
        product << raw_tag('ProductionCode', item.code)
        product << raw_tag('Description', item.name)
        product << raw_tag('Quantity', item.quantity)
        product << raw_tag('UnitPrice', item.unit_price)
        add_dtype(product, item.d_type)
        product
      end

      # DType (稅別註記) is required on every detail line only for mixed-tax
      # invoices (TaxType == 9).
      def add_dtype(product, value)
        return unless @data.mixed_tax?

        product << raw_tag('DType', value)
      end
    end
  end
end
