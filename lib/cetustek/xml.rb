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
  end
end
