# frozen_string_literal: true

module Cetustek
  # 2.2 CancelInvoice 作廢發票確認. Returns "C0" on success, raises ResultError
  # otherwise. Uploading is not the end of it — the cancellation still has to be
  # confirmed manually on the 鯨躍 platform before the invoice counts as void.
  class CancelInvoice
    include Soap

    SUCCESS_CODE = 'C0'
    MAX_REMARK_LENGTH = 20

    # Spec AVM-26-03 Table 10.
    RESULT_MESSAGES = ResultCode::COMMON.merge(
      'C1' => '資料庫發生錯誤',
      'C2' => '資料有誤',
      'C3' => '該發票已過申報期間，需填入核准作廢文號 (return_tax_document_number)',
      'C4' => '無此發票號碼可以作廢',
      'C5' => '該發票已經作廢過',
      'C6' => '作廢資訊已經傳送過'
    ).freeze

    # remark 是 Table 9 的必填作廢原因，沒有預設值可用：理由是業務決定的。
    def initialize(invoice_number, invoice_year, remark:, return_tax_document_number: nil)
      raise ArgumentError, 'invoice_number is required' if invoice_number.to_s.strip.empty?
      raise ArgumentError, 'invoice_year is required' if invoice_year.to_s.strip.empty?
      raise ArgumentError, 'remark (作廢原因) is required' if remark.to_s.strip.empty?
      raise ArgumentError, "remark must not exceed #{MAX_REMARK_LENGTH} characters" if remark.length > MAX_REMARK_LENGTH

      @invoice_number = invoice_number
      @invoice_year = invoice_year
      @remark = remark
      @return_tax_document_number = return_tax_document_number
    end

    def execute
      response = soap_call(:cancel_invoice, invoicexml: generate_xml)
      ResultCode.check!(soap_return(response, :cancel_invoice), RESULT_MESSAGES, success: SUCCESS_CODE)
    end

    private

    def generate_xml
      Xml.document('Invoice') do |invoice|
        Xml.append(invoice, 'InvoiceNumber', @invoice_number)
        Xml.append(invoice, 'InvoiceYear', @invoice_year)
        # 專案作廢核准文號：只在超過申報期間作廢時才需要 (Table 10 的 C3)。
        Xml.append(invoice, 'ReturnTaxDocumentNumber', @return_tax_document_number, skip_nil: true)
        Xml.append(invoice, 'Remark', @remark)
      end
    end
  end
end
