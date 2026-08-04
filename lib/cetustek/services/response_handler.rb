# frozen_string_literal: true

require 'json'

module Cetustek
  module Services
    # Parses the CreateInvoiceV3 return value. Three shapes are possible:
    # the Table 8 JSON object (RtnMsg=Json), the 15-character
    # "發票號碼;隨機碼" string, or a bare Table 7 result code.
    class ResponseHandler
      # Kept as a ResultError subclass so pre-0.7 rescues keep working.
      # @deprecated rescue Cetustek::ResultError instead.
      class InvalidResponseError < ResultError; end

      SUCCESS_LENGTH = 15 # 發票號碼 10 碼 + ';' + 隨機碼 4 碼

      # Spec AVM-26-03 Table 7.
      RESULT_MESSAGES = {
        'M:' => '欄位未填或格式錯誤',
        'M0' => 'XML 格式錯誤',
        'M1' => 'XML 格式錯誤',
        'D0' => '沒有產品明細',
        'D0_' => '產品編號格式錯誤',
        'D1_' => '品名未填或格式錯誤',
        'D2_' => '數量未填或格式錯誤',
        'D3_' => '單價未填或格式錯誤',
        'D4_' => '單位格式錯誤',
        'D5_' => '數量*單價，其小計整數位大於 13 位',
        'D999' => '明細筆數最多 9999 筆',
        'S1' => '資料庫發生錯誤',
        'S2' => '訂單日期超過開立日期',
        'S3' => '未在申報期內',
        'S4' => '未取得發票號碼',
        'S5' => '發票號碼已使用完畢',
        'S6' => '超過租賃張數限制',
        'S7' => '訂單號碼已存在，若需重開請先作廢原發票號碼',
        'S8' => '開立的總金額為負值',
        'Invalid' => '無效 IP，請通知系統商'
      }.freeze

      def initialize(response, invoice_data = nil, xml = nil)
        @response = response
        @invoice_data = invoice_data
        @xml = xml
      end

      def process
        body = @response.body[:create_invoice_v3_response][:return].to_s.strip
        json = parse_json(body)

        return success(json_result(json)) if json && json['msg'] == 'Success'
        return success(string_result(body)) if json.nil? && success_string?(body)

        fail_with(json ? json['msg'].to_s : body)
      end

      private

      # M1 (XML 格式錯誤) 與 Invalid 不會回傳 JSON，所以形狀要靠內容判斷。
      def parse_json(body)
        return nil unless body.start_with?('{')

        JSON.parse(body)
      rescue JSON::ParserError
        nil
      end

      def success_string?(body)
        body.length == SUCCESS_LENGTH && body.include?(';')
      end

      def json_result(json)
        {
          number: json['invnumber'],
          random_number: json['random'],
          date: json['invdate'],
          time: json['invtime'],
          sale_amount: json['saleamt'],
          zero_amount: json['zeroamt'],
          free_amount: json['freeamt'],
          tax_amount: json['taxamt'],
          total_amount: json['totalamt'],
          carrier_url: json['ctkurl']
        }
      end

      def string_result(body)
        number, random_number = body.split(';')
        { number: number, random_number: random_number }
      end

      def success(result)
        logger&.info("CreateInvoiceV3 #{order_id} #{result[:number]}")
        result
      end

      def fail_with(code)
        logger&.error("CreateInvoiceV3 #{order_id} #{code}")
        logger&.debug(@xml) if @xml
        raise InvalidResponseError.new(code, ResultCode.describe(code, RESULT_MESSAGES))
      end

      def logger
        Cetustek.config.logger
      end

      def order_id
        @invoice_data&.order_id
      end
    end
  end
end
