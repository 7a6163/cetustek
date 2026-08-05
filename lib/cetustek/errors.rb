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
    # Rows that are identical across the spec's result tables (7/10/17/19).
    COMMON = {
      'M:' => '欄位未填或格式錯誤',
      'M0' => 'XML 格式錯誤',
      'M1' => 'XML 格式錯誤',
      'Invalid' => '無效 IP，請通知系統商'
    }.freeze

    # Detail-line rows, identical between Table 7 (發票) and Table 17 (折讓).
    DETAILS = {
      'D0' => '沒有產品明細',
      'D0_' => '產品編號格式錯誤',
      'D1_' => '品名未填或格式錯誤',
      'D2_' => '數量未填或格式錯誤',
      'D3_' => '單價未填或格式錯誤',
      'D4_' => '單位格式錯誤',
      'D5_' => '數量*單價，其小計整數位大於 13 位',
      'D999' => '明細筆數最多 9999 筆'
    }.freeze

    # Codes may carry a suffix naming the offending field or detail row
    # ("M:AllowanceDate", "D2_3"), so an exact miss falls back to the table key
    # without the suffix.
    def self.describe(code, messages)
      messages[code] || messages[code.to_s.sub(/(?<=[:_]).*\z/, '')]
    end

    # Returns the code on success, otherwise raises ResultError.
    def self.check!(code, messages, success:)
      return code if code == success

      raise!(code, messages)
    end

    def self.raise!(code, messages)
      raise ResultError.new(code, describe(code, messages))
    end
  end
end
