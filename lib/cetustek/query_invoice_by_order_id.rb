# frozen_string_literal: true

module Cetustek
  # 2.5 QueryInvoicebyOrderid 以訂單編號查詢發票資訊
  class QueryInvoiceByOrderId
    extend Soap

    def self.query(order_id)
      soap_call(:query_invoice_by_orderid, orderid: order_id)
    end
  end
end
