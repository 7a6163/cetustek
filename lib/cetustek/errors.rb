# frozen_string_literal: true

module Cetustek
  class Error < StandardError; end

  # Raised when an API call returns a result code other than the success code.
  class ResultError < Error
    attr_reader :code

    def initialize(code, description = nil)
      @code = code
      super([code, description].compact.join(' - '))
    end
  end

  module ResultCode
    # Codes may carry a suffix naming the offending field or detail row
    # ("M:AllowanceDate", "D2_3"), so an exact miss falls back to the table key
    # without the suffix.
    def self.describe(code, messages)
      messages[code] || messages[code.to_s.sub(/(?<=[:_]).*\z/, '')]
    end

    # Returns the code on success, otherwise raises ResultError.
    def self.check!(code, messages, success:)
      return code if code == success

      raise ResultError.new(code, describe(code, messages))
    end
  end
end
