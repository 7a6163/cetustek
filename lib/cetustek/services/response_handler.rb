# frozen_string_literal: true

require 'logger'

module Cetustek
  module Services
    class ResponseHandler
      class InvalidResponseError < StandardError; end

      def initialize(response, invoice_data, xml = nil)
        @response = response
        @invoice_data = invoice_data
        @xml = xml
      end

      def process
        response_body = @response.body[:create_invoice_v3_response][:return]
        number, random_number = response_body.split(';')

        unless random_number
          log_error
          raise InvalidResponseError, "Invalid response: #{response_body}"
        end

        { number: number, random_number: random_number }
      end

      private

      def log_error
        return unless defined?(Rails) && @xml

        logger = Logger.new(Rails.root.join('log/invoice_xml.log'))
        logger.debug("#{@invoice_data.order_id} - #{@xml.force_encoding('UTF-8')}")
      end
    end
  end
end
