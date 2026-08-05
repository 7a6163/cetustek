# frozen_string_literal: true

require 'ox'

module Cetustek
  # @deprecated use Cetustek::Soap. Kept so `extend Queries` keeps working.
  Queries = Soap

  # 2.4 QueryInvoice 查詢發票資訊 (by invoice number + year)
  class QueryInvoice
    extend Queries

    def self.query(invoice_number, invoice_year)
      soap_client.call(:query_invoice, message: {
                         invoicenumber: invoice_number,
                         invoiceyear: invoice_year,
                         source: source,
                         rentid: rentid
                       })
    end
  end

  # 2.6 QueryInvoiceNumberbyOrderid 以訂單編號查詢發票號碼
  class QueryInvoiceNumberByOrderId
    extend Queries

    def self.query(order_id)
      soap_client.call(:query_invoice_number_by_orderid, message: {
                         orderid: order_id,
                         source: source,
                         rentid: rentid
                       })
    end
  end

  # 2.11 QueryAllowance 查詢折讓資料
  class QueryAllowance
    extend Queries

    # Spec AVM-26-03 Table 20. Note the query response uses ProductCode and
    # InvoiceDate, unlike CreateAllowance's ProductionCode and InvoiceYear.
    FIELDS = %w[AllowanceNumber AllowanceDate InvoiceNumber InvoiceDate
                BuyerIdentifier BuyerName BuyerAddress Reason AllowanceStatus
                BackStatus SaleAmount TaxAmount].freeze
    DETAIL_FIELDS = %w[SequenceNumber ProductCode Description Quantity Unit
                       UnitPrice Amount Tax TaxType].freeze

    def self.query(allowance_number)
      soap_client.call(:query_allowance, message: {
                         allowancenumber: allowance_number,
                         source: source,
                         rentid: rentid
                       })
    end

    # Same query, with the returned XML parsed into a Hash of snake_case keys
    # plus a :details array. Values are the raw strings from the XML; returns
    # nil when the platform answers with nothing at all.
    def self.find(allowance_number)
      parse(soap_return(query(allowance_number), :query_allowance))
    end

    def self.parse(xml)
      body = xml.to_s.strip
      return nil if body.empty?
      # §2.11 只描述成功時的 XML；非 XML 的回覆是代碼字串，原樣拋給呼叫端。
      ResultCode.raise!(body, ResultCode::COMMON) unless body.start_with?('<')

      root = Ox.parse(body)
      root = root.root if root.is_a?(Ox::Document)

      data = FIELDS.to_h { |field| [snake_case(field), text_of(root, field)] }
      data[:details] = root.locate('Details/ProductItem').map do |item|
        DETAIL_FIELDS.to_h { |field| [snake_case(field), text_of(item, field)] }
      end
      data
    end

    def self.text_of(element, name)
      element.locate(name).first&.text
    end

    def self.snake_case(name)
      name.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym
    end

    private_class_method :text_of, :snake_case
  end
end
