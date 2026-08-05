# frozen_string_literal: true

require 'json'

module Cetustek
  module Services
    # Parses the CreateInvoiceV3 return value. Three shapes are possible:
    # the Table 8 JSON object (RtnMsg=Json), the 15-character
    # "發票號碼;隨機碼" string, or a bare Table 7 result code.
    class ResponseHandler
      # @deprecated rescue Cetustek::ResultError instead. Kept as an alias of
      #   the class actually raised so pre-0.7 rescues keep matching.
      InvalidResponseError = ResultError

      SUCCESS_LENGTH = 15 # 發票號碼 10 碼 + ';' + 隨機碼 4 碼

      # Spec AVM-26-03 Table 7.
      RESULT_MESSAGES = ResultCode::COMMON.merge(ResultCode::DETAILS).merge(
        'S1' => '資料庫發生錯誤',
        'S2' => '訂單日期超過開立日期',
        'S3' => '未在申報期內',
        'S4' => '未取得發票號碼',
        'S5' => '發票號碼已使用完畢',
        'S6' => '超過租賃張數限制',
        'S7' => '訂單號碼已存在，若需重開請先作廢原發票號碼',
        'S8' => '開立的總金額為負值'
      ).freeze

      def initialize(response, invoice_data, xml = nil)
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
        ResultCode.raise!(code, RESULT_MESSAGES)
      end

      def logger
        Cetustek.config.logger
      end

      def order_id
        @invoice_data.order_id
      end
    end
  end
end
