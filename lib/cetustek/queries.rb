# frozen_string_literal: true

module Cetustek
  # Read-only SOAP queries. Each returns the raw Savon response, mirroring
  # QueryInvoiceByOrderId. Spec AVM-26-03 §2.4 / §2.6 / §2.11.
  module Queries
    def soap_client
      Savon.client(wsdl: Cetustek.config.url, open_timeout: 300, read_timeout: 300)
    end

    def source
      Cetustek.config.site_id + Cetustek.config.password
    end

    def rentid
      Cetustek.config.username
    end
  end

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

    def self.query(allowance_number)
      soap_client.call(:query_allowance, message: {
                         allowancenumber: allowance_number,
                         source: source,
                         rentid: rentid
                       })
    end
  end
end
