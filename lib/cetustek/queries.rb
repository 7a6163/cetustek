# frozen_string_literal: true

module Cetustek
  # @deprecated use Cetustek::Soap. Kept so `extend Queries` keeps working.
  Queries = Soap

  # 2.4 QueryInvoice 查詢發票資訊 (by invoice number + year)
  class QueryInvoice
    extend Soap

    # Spec AVM-26-03 Table 13.
    FIELDS = %w[OrderID InvoiceNumber InvoiceDate InvoiceTime MainRemark CheckNumber
                RandomNumber InvoiceStatus DonateMark SalesAmount FreeTaxSalesAmount
                ZeroTaxSalesAmount TaxAmount TotalAmount CtkUrl].freeze
    PARTY_FIELDS = %w[Identifier Name Address PersonInCharge TelephoneNumber
                      FacsimileNumber EmailAddress].freeze
    DETAIL_FIELDS = %w[ProductCode Description Quantity Unit UnitPrice Amount SequenceNumber].freeze

    def self.query(invoice_number, invoice_year)
      soap_call(:query_invoice, invoicenumber: invoice_number, invoiceyear: invoice_year)
    end

    # Same query, with the returned XML parsed into a Hash of snake_case keys
    # plus :seller/:buyer sub-hashes and a :details array. nil when the
    # platform answers with nothing at all, or the documented "nodata".
    def self.find(invoice_number, invoice_year)
      parse(soap_return(query(invoice_number, invoice_year), :query_invoice))
    end

    # §2.5 QueryInvoicebyOrderid shares this exact XML shape (Table 13), so
    # QueryInvoiceByOrderId#find reuses this instead of duplicating it.
    def self.parse(xml)
      root = Xml.parse_response(xml, nil_values: %w[nodata])
      return nil unless root

      data = Xml.parse_fields(root, FIELDS)
      data[:seller] = parse_party(root, 'Seller')
      data[:buyer] = parse_party(root, 'Buyer')
      data[:details] = root.locate('Details/ProductItem').map { |item| Xml.parse_fields(item, DETAIL_FIELDS) }
      data
    end

    def self.parse_party(root, name)
      element = root.locate(name).first
      element && Xml.parse_fields(element, PARTY_FIELDS)
    end

    private_class_method :parse_party
  end

  # 2.6 QueryInvoiceNumberbyOrderid 以訂單編號查詢發票號碼
  class QueryInvoiceNumberByOrderId
    extend Soap

    # 發票號碼格式，字軌 2 碼大寫字母+8 碼數字 (Table 9). Anything else that
    # isn't the "nodata" sentinel is a bare result code, not a number.
    FORMAT = /\A[A-Z]{2}\d{8}\z/

    def self.query(order_id)
      soap_call(:query_invoice_number_by_orderid, orderid: order_id)
    end

    # Same query, returning just the bare invoice number string, or nil for
    # an empty response or the documented "nodata". A response that isn't
    # either shape is a result code, raised as ResultError like the other
    # Query* classes — it used to be returned as if it were the number.
    def self.find(order_id)
      body = soap_return(query(order_id), :query_invoice_number_by_orderid).to_s.strip
      return nil if body.empty? || body == 'nodata'
      return body if body.match?(FORMAT)

      ResultCode.raise!(body, ResultCode::COMMON)
    end
  end

  # 2.11 QueryAllowance 查詢折讓資料
  class QueryAllowance
    extend Soap

    # Spec AVM-26-03 Table 20. Note the query response uses ProductCode and
    # InvoiceDate, unlike CreateAllowance's ProductionCode and InvoiceYear.
    FIELDS = %w[AllowanceNumber AllowanceDate InvoiceNumber InvoiceDate
                BuyerIdentifier BuyerName BuyerAddress Reason AllowanceStatus
                BackStatus SaleAmount TaxAmount].freeze
    DETAIL_FIELDS = %w[SequenceNumber ProductCode Description Quantity Unit
                       UnitPrice Amount Tax TaxType].freeze

    def self.query(allowance_number)
      soap_call(:query_allowance, allowancenumber: allowance_number)
    end

    # Same query, with the returned XML parsed into a Hash of snake_case keys
    # plus a :details array. Values are the raw strings from the XML; returns
    # nil when the platform answers with nothing at all.
    def self.find(allowance_number)
      parse(soap_return(query(allowance_number), :query_allowance))
    end

    def self.parse(xml)
      root = Xml.parse_response(xml)
      return nil unless root

      data = Xml.parse_fields(root, FIELDS)
      data[:details] = root.locate('Details/ProductItem').map { |item| Xml.parse_fields(item, DETAIL_FIELDS) }
      data
    end
  end
end
