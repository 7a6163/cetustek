# frozen_string_literal: true

require 'ox'
require 'cgi'

module Cetustek
  # 2.9 CreateAllowance 開立折讓單. Returns the result code (A0 = success).
  # check_allowance: 0 = confirmed allowance (default), 1 = unconfirmed.
  class CreateAllowance
    def initialize(allowance_data, check_allowance: 0)
      @data = allowance_data
      @check_allowance = check_allowance
    end

    def execute
      perform
      @response.body[:create_allowance_response][:return]
    end

    private

    def perform
      client = Savon.client(wsdl: Cetustek.config.url, open_timeout: 300, read_timeout: 300)
      @response = client.call(:create_allowance, message: {
                                allowancexml: generate_xml,
                                checkallowance: @check_allowance,
                                source: Cetustek.config.site_id + Cetustek.config.password,
                                rentid: Cetustek.config.username
                              })
    end

    def generate_xml
      doc = Ox::Document.new
      instruct = Ox::Instruct.new(:xml)
      instruct[:version] = '1.0'
      instruct[:encoding] = 'UTF-8'
      doc << instruct

      allowance = Ox::Element.new('Allowance')
      allowance[:XSDVersion] = '2.8'
      doc << allowance

      allowance << raw_tag('AllowanceNumber', @data.allowance_number)
      allowance << raw_tag('AllowanceDate', @data.allowance_date.strftime('%Y/%m/%d'))
      allowance << raw_tag('InvoiceNumber', @data.invoice_number)
      allowance << raw_tag('InvoiceYear', @data.invoice_year)
      allowance << raw_tag('BuyerAddress', @data.buyer_address)
      allowance << raw_tag('BuyerEmailAddress', @data.buyer_email)
      allowance << raw_tag('TaxType', @data.tax_type)
      allowance << raw_tag('Reason', @data.reason)
      allowance << raw_tag('RoundNum', @data.round_num) unless @data.round_num.nil?
      allowance << build_details

      Ox.dump(doc).force_encoding('UTF-8')
    end

    def build_details
      details = Ox::Element.new('Details')
      @data.items.each do |item|
        product = Ox::Element.new('ProductItem')
        product << raw_tag('ProductionCode', item.code)
        product << raw_tag('Description', item.name)
        product << raw_tag('Quantity', item.quantity)
        product << raw_tag('Unit', item.unit)
        product << raw_tag('UnitPrice', item.unit_price)
        details << product
      end
      details
    end

    def raw_tag(name, value)
      Ox::Raw.new("<#{name}>#{CGI.escapeHTML(value.to_s)}</#{name}>")
    end
  end
end
