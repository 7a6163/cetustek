module Cetustek
  class QueryInvoiceByOrderId
    def self.query(order_id)
      url = Cetustek.config.url
      client = Savon.client(
        wsdl: url,
        open_timeout: 300,
        read_timeout: 300
      )

      @response = client.call(:query_invoice_by_orderid, message:
        {
          orderid: order_id,
          source: Cetustek.config.site_id + Cetustek.config.password,
          rentid: Cetustek.config.username
        })
    end
  end
end
