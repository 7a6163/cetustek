# frozen_string_literal: true

module Cetustek
  # 2.10 CancelAllowance 作廢折讓單. Returns "C0" on success, raises ResultError otherwise.
  class CancelAllowance
    include Soap

    SUCCESS_CODE = 'C0'
    MAX_REASON_LENGTH = 20

    # Spec AVM-26-03 Table 19.
    RESULT_MESSAGES = ResultCode::COMMON.merge(
      'C1' => '上傳失敗',
      'C2' => '折讓單已申報，無法作廢',
      'C3' => '折讓單號不存在或須為已確認後的折讓單',
      'C4' => '該作廢折讓單已經上傳',
      'C5' => '折讓單已過作廢期限，無法作廢'
    ).freeze

    # Table 18 has only these two fields, both 必填.
    def initialize(allowance_number, reason)
      raise ArgumentError, 'allowance_number is required' if allowance_number.to_s.strip.empty?
      raise ArgumentError, 'reason (作廢原因) is required' if reason.to_s.strip.empty?
      raise ArgumentError, "reason must not exceed #{MAX_REASON_LENGTH} characters" if reason.length > MAX_REASON_LENGTH

      @allowance_number = allowance_number
      @reason = reason
    end

    def execute
      response = soap_call(:cancel_allowance, allowancexml: generate_xml)
      ResultCode.check!(soap_return(response, :cancel_allowance), RESULT_MESSAGES, success: SUCCESS_CODE)
    end

    private

    def generate_xml
      Xml.document('Allowance') do |allowance|
        Xml.append(allowance, 'AllowanceNumber', @allowance_number)
        Xml.append(allowance, 'Reason', @reason)
      end
    end
  end
end
