# frozen_string_literal: true

require_relative 'models/invoice_data'
require_relative 'services/invoice_xml_builder'
require_relative 'services/response_handler'

module Cetustek
  # 2.1 CreateInvoiceV3 開立發票. Returns the issued invoice on success and
  # raises ResultError otherwise. Persisting the result is the caller's job.
  class CreateInvoice
    include Soap

    def initialize(invoice_data)
      @invoice_data = invoice_data
    end

    def execute
      xml = Services::InvoiceXmlBuilder.new(@invoice_data).build
      # hastax: 0 = 明細單價未稅, 1 = 含稅; comes from the order, not a constant.
      response = soap_call(:create_invoice_v3, invoicexml: xml, hastax: @invoice_data.hastax)
      Services::ResponseHandler.new(response, @invoice_data, xml).process
    end
  end
end
