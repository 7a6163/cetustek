# frozen_string_literal: true

require_relative 'models/invoice_data'
require_relative 'services/invoice_xml_builder'
require_relative 'services/invoice_service'
require_relative 'services/response_handler'

module Cetustek
  class CreateInvoice
    def initialize(invoice_data)
      @invoice_data = invoice_data
    end

    def execute
      xml = Services::InvoiceXmlBuilder.new(@invoice_data).build
      response = Services::InvoiceService.new(xml, @invoice_data.order_id).create
      result = Services::ResponseHandler.new(response, @invoice_data, xml).process
      
      if defined?(Rails) && result[:number] && result[:random_number]
        update_invoice_info(result)
      end
      
      result
    end

    private

    def update_invoice_info(result)
      return unless @invoice_data.respond_to?(:invoice_info)
      
      @invoice_data.invoice_info.update(
        number: result[:number],
        random_number: result[:random_number],
        created_at: Time.zone.today
      )
    end
  end
end
