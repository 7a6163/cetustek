# frozen_string_literal: true

module Cetustek
  module Services
    class InvoiceXmlBuilder
      def initialize(invoice_data)
        @data = invoice_data
      end

      def build
        Xml.document('Invoice') do |invoice|
          add_basic_info(invoice)
          add_buyer_info(invoice)
          add_invoice_type_info(invoice)
          add_details(invoice)
        end
      end

      private

      def add_basic_info(invoice)
        Xml.append(invoice, 'OrderId', @data.order_id)
        Xml.append(invoice, 'OrderDate', @data.order_date.strftime('%Y/%m/%d'))
      end

      def add_buyer_info(invoice)
        Xml.append(invoice, 'BuyerIdentifier', @data.buyer_identifier)
        Xml.append(invoice, 'BuyerName', @data.buyer_name)
        Xml.append(invoice, 'BuyerAddress', @data.buyer_address)
        Xml.append(invoice, 'BuyerPersonInCharge', @data.buyer_person_in_charge)
        Xml.append(invoice, 'BuyerTelephoneNumber', @data.buyer_telephone)
        Xml.append(invoice, 'BuyerFacsimileNumber', @data.buyer_facsimile)
        Xml.append(invoice, 'BuyerEmailAddress', @data.buyer_email)
        Xml.append(invoice, 'BuyerCustomerNumber', @data.buyer_customer_number)
      end

      def add_invoice_type_info(invoice)
        Xml.append(invoice, 'DonateMark', @data.donate_mark)
        Xml.append(invoice, 'InvoiceType', @data.invoice_type)
        Xml.append(invoice, 'CarrierType', @data.carrier_type)
        Xml.append(invoice, 'CarrierId1', @data.carrier_id1)
        Xml.append(invoice, 'CarrierId2', @data.carrier_id2)
        Xml.append(invoice, 'NPOBAN', @data.npo_ban)
        Xml.append(invoice, 'TaxType', @data.tax_type)
        Xml.append(invoice, 'TaxRate', @data.tax_rate)
        Xml.append(invoice, 'ZeroReason', @data.zero_reason, skip_nil: true)
        Xml.append(invoice, 'PayWay', @data.payment_type)
        Xml.append(invoice, 'Remark', @data.remark)
        Xml.append(invoice, 'MailSend', @data.mail_send, skip_nil: true)
        Xml.append(invoice, 'RoundNum', @data.round_num, skip_nil: true)
        Xml.append(invoice, 'RtnMsg', @data.rtn_msg, skip_nil: true)
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
        Xml.append(product, 'ProductionCode', item.code)
        Xml.append(product, 'Description', item.name)
        Xml.append(product, 'Quantity', item.quantity)
        Xml.append(product, 'Unit', item.unit)
        Xml.append(product, 'UnitPrice', item.unit_price)
        # DType (稅別註記) is required on every detail line only for mixed-tax
        # invoices (TaxType == 9).
        Xml.append(product, 'DType', item.d_type) if @data.mixed_tax?
        product
      end
    end
  end
end
