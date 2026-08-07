# frozen_string_literal: true

require 'ox'
require 'cgi'

module Cetustek
  # Every request document in the spec is the same shape: a UTF-8 declaration
  # and a single <Invoice>/<Allowance> root carrying XSDVersion.
  module Xml
    XSD_VERSION = '2.8'

    module_function

    def document(root_name)
      doc = Ox::Document.new
      instruct = Ox::Instruct.new(:xml)
      instruct[:version] = '1.0'
      instruct[:encoding] = 'UTF-8'
      doc << instruct

      root = Ox::Element.new(root_name)
      root[:XSDVersion] = XSD_VERSION
      doc << root
      yield root

      Ox.dump(doc).force_encoding('UTF-8')
    end

    # Values are HTML-escaped so that special characters (&, <, >, ", ') in any
    # dynamic field cannot break the XML or be used for injection.
    def tag(name, value)
      Ox::Raw.new("<#{name}>#{CGI.escapeHTML(value.to_s)}</#{name}>")
    end

    # Fields whose 備註 says "若未填，預設 X" are left out entirely when nil, so
    # the platform applies its own default instead of parsing an empty value.
    def append(element, name, value, skip_nil: false)
      return if skip_nil && value.nil?

      element << tag(name, value)
    end

    # Shared guard every Query* class needs before it can parse a response
    # body: nil for an empty answer or one of the documented sentinel strings
    # (e.g. "nodata"); ResultError for a bare result code; otherwise the
    # parsed root element, ready for parse_fields.
    def parse_response(body, nil_values: [])
      text = body.to_s.strip
      return nil if text.empty? || nil_values.include?(text)

      ResultCode.raise!(text, ResultCode::COMMON) unless text.start_with?('<')

      root = Ox.parse(text)
      root.is_a?(Ox::Document) ? root.root : root
    end

    # Shared response-parsing side: every Query* class turns a response
    # element into a Hash of snake_case keys, so this lives here once instead
    # of once per query class.
    def parse_fields(element, fields)
      fields.to_h { |field| [snake_case(field), text_of(element, field)] }
    end

    def text_of(element, name)
      element&.locate(name)&.first&.text
    end

    def snake_case(name)
      name.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym
    end
  end
end
