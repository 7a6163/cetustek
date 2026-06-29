# frozen_string_literal: true

require 'ox'
require 'cgi'

module Cetustek
  # 2.10 CancelAllowance 作廢折讓單. Returns the result code (C0 = success).
  class CancelAllowance
    def initialize(allowance_number, reason)
      @allowance_number = allowance_number
      @reason = reason
    end

    def execute
      perform
      @response.body[:cancel_allowance_response][:return]
    end

    private

    def perform
      client = Savon.client(wsdl: Cetustek.config.url, open_timeout: 300, read_timeout: 300)
      @response = client.call(:cancel_allowance, message: {
                                allowancexml: generate_xml,
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

      allowance << raw_tag('AllowanceNumber', @allowance_number)
      allowance << raw_tag('Reason', @reason)

      Ox.dump(doc).force_encoding('UTF-8')
    end

    def raw_tag(name, value)
      Ox::Raw.new("<#{name}>#{CGI.escapeHTML(value.to_s)}</#{name}>")
    end
  end
end
