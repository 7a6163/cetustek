# frozen_string_literal: true

require 'ox'
require 'cgi'

module Cetustek
  # 2.9 CreateAllowance 開立折讓單. Returns "A0" on success, raises ResultError otherwise.
  class CreateAllowance
    SUCCESS_CODE = 'A0'

    # Spec AVM-26-03 Table 17.
    RESULT_MESSAGES = {
      'M:' => '欄位未填或格式錯誤',
      'M1' => 'XML 格式錯誤',
      'D0' => '沒有產品明細',
      'D0_' => '產品編號格式錯誤',
      'D1_' => '品名未填或格式錯誤',
      'D2_' => '數量未填或格式錯誤',
      'D3_' => '單價未填或格式錯誤',
      'D4_' => '單位格式錯誤',
      'D5_' => '數量*單價，其小計整數位大於 13 位',
      'D999' => '明細筆數最多 9999 筆',
      'A1' => '上傳失敗',
      'A2' => '所有折讓金額加總不能大於原發票金額',
      'A3' => '發票號碼不存在',
      'A4' => '發票號碼已經被作廢',
      'A5' => '折讓單已經上傳',
      'A6' => '折讓總金額須大於零',
      'A7' => '折讓日期應大於原發票開立日期',
      'Invalid' => '無效 IP，請通知系統商'
    }.freeze

    # check_allowance 只剩 0（已確認的折讓單）：規格 §2.9 已刪除 1，
    # 114/01/01 起上傳的折讓單皆為已確認。
    def initialize(allowance_data, check_allowance: 0)
      raise ArgumentError, 'check_allowance must be 0 (114/01/01 起折讓單皆為已確認)' unless check_allowance.to_i.zero?

      @data = allowance_data
      @check_allowance = 0
    end

    def execute
      perform
      ResultCode.check!(@response.body[:create_allowance_response][:return],
                        RESULT_MESSAGES, success: SUCCESS_CODE)
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
