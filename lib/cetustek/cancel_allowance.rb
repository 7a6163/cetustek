# frozen_string_literal: true

require 'ox'
require 'cgi'

module Cetustek
  # 2.10 CancelAllowance 作廢折讓單. Returns "C0" on success, raises ResultError otherwise.
  class CancelAllowance
    SUCCESS_CODE = 'C0'

    # Spec AVM-26-03 Table 19.
    RESULT_MESSAGES = {
      'M:' => '欄位未填或格式錯誤',
      'M1' => 'XML 格式錯誤',
      'C1' => '上傳失敗',
      'C2' => '折讓單已申報，無法作廢',
      'C3' => '折讓單號不存在或須為已確認後的折讓單',
      'C4' => '該作廢折讓單已經上傳',
      'C5' => '折讓單已過作廢期限，無法作廢',
      'Invalid' => '無效 IP，請通知系統商'
    }.freeze

    def initialize(allowance_number, reason)
      @allowance_number = allowance_number
      @reason = reason
    end

    def execute
      perform
      ResultCode.check!(@response.body[:cancel_allowance_response][:return],
                        RESULT_MESSAGES, success: SUCCESS_CODE)
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
