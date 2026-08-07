# frozen_string_literal: true

module Cetustek
  # 2.5 QueryInvoicebyOrderid 以訂單編號查詢發票資訊
  class QueryInvoiceByOrderId
    extend Soap

    def self.query(order_id)
      soap_call(:query_invoice_by_orderid, orderid: order_id)
    end

    # Same query, parsed into a Hash. §2.5 shares Table 13's XML shape with
    # §2.4, so this reuses QueryInvoice.parse instead of duplicating it.
    def self.find(order_id)
      QueryInvoice.parse(soap_return(query(order_id), :query_invoice_by_orderid))
    end
  end
end
