# frozen_string_literal: true

module Cetustek
  # 2.9 CreateAllowance 開立折讓單. Returns "A0" on success, raises ResultError otherwise.
  class CreateAllowance
    include Soap

    SUCCESS_CODE = 'A0'

    # Spec AVM-26-03 Table 17.
    RESULT_MESSAGES = ResultCode::COMMON.merge(ResultCode::DETAILS).merge(
      'A1' => '上傳失敗',
      'A2' => '所有折讓金額加總不能大於原發票金額',
      'A3' => '發票號碼不存在',
      'A4' => '發票號碼已經被作廢',
      'A5' => '折讓單已經上傳',
      'A6' => '折讓總金額須大於零',
      'A7' => '折讓日期應大於原發票開立日期'
    ).freeze

    # check_allowance 只剩 0（已確認的折讓單）：規格 §2.9 已刪除 1，
    # 114/01/01 起上傳的折讓單皆為已確認。
    def initialize(allowance_data, check_allowance: 0)
      raise ArgumentError, 'check_allowance must be 0 (114/01/01 起折讓單皆為已確認)' unless check_allowance.to_i.zero?

      @data = allowance_data
      @check_allowance = 0
    end

    def execute
      response = soap_call(:create_allowance, allowancexml: generate_xml, checkallowance: @check_allowance)
      ResultCode.check!(soap_return(response, :create_allowance), RESULT_MESSAGES, success: SUCCESS_CODE)
    end

    private

    def generate_xml
      Xml.document('Allowance') do |allowance|
        Xml.append(allowance, 'AllowanceNumber', @data.allowance_number)
        Xml.append(allowance, 'AllowanceDate', @data.allowance_date.strftime('%Y/%m/%d'))
        Xml.append(allowance, 'InvoiceNumber', @data.invoice_number)
        Xml.append(allowance, 'InvoiceYear', @data.invoice_year)
        Xml.append(allowance, 'BuyerAddress', @data.buyer_address)
        Xml.append(allowance, 'BuyerEmailAddress', @data.buyer_email)
        Xml.append(allowance, 'TaxType', @data.tax_type)
        Xml.append(allowance, 'Reason', @data.reason)
        Xml.append(allowance, 'RoundNum', @data.round_num, skip_nil: true)
        allowance << build_details
      end
    end

    def build_details
      details = Ox::Element.new('Details')
      @data.items.each do |item|
        product = Ox::Element.new('ProductItem')
        Xml.append(product, 'ProductionCode', item.code)
        Xml.append(product, 'Description', item.name)
        Xml.append(product, 'Quantity', item.quantity)
        Xml.append(product, 'Unit', item.unit)
        Xml.append(product, 'UnitPrice', item.unit_price)
        details << product
      end
      details
    end
  end
end
