# frozen_string_literal: true

require 'savon'

module Cetustek
  module Services
    # 2.1 CreateInvoiceV3(invoicexml, hastax, rentid, source)
    class InvoiceService
      def initialize(xml, hastax = 1)
        @xml = xml
        @hastax = hastax
      end

      def create
        Savon.client(
          wsdl: Cetustek.config.url,
          open_timeout: 300,
          read_timeout: 300
        ).call(:create_invoice_v3, message: {
                 invoicexml: @xml,
                 source: Cetustek.config.site_id + Cetustek.config.password,
                 rentid: Cetustek.config.username,
                 hastax: @hastax
               })
      end
    end
  end
end
