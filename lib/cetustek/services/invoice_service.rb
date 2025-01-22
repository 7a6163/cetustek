# frozen_string_literal: true

require 'savon'
require 'logger'

module Cetustek
  module Services
    class InvoiceService
      def initialize(xml, order_id = nil)
        @xml = xml
        @order_id = order_id
      end

      def create
        client = build_soap_client
        response = call_create_invoice(client)
        log_response(response)
        response
      end

      private

      def build_soap_client
        Savon.client(
          wsdl: Cetustek.config.url,
          open_timeout: 300,
          read_timeout: 300
        )
      end

      def call_create_invoice(client)
        client.call(:create_invoice_v3, message: {
          invoicexml: @xml,
          source: Cetustek.config.site_id + Cetustek.config.password,
          rentid: Cetustek.config.username,
          hastax: 1
        })
      end

      def log_response(response)
        return unless defined?(Rails)

        logger = Logger.new(Rails.root.join('log/invoice.log'))
        logger.debug("#{@order_id} - #{response.body}") if @order_id
      end
    end
  end
end
