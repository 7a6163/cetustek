# frozen_string_literal: true

require 'ox'
require 'cgi'

module Cetustek
  # 2.2 CancelInvoice 作廢發票確認. Returns "C0" on success, raises ResultError
  # otherwise. Uploading is not the end of it — the cancellation still has to be
  # confirmed manually on the 鯨躍 platform before the invoice counts as void.
  class CancelInvoice
    SUCCESS_CODE = 'C0'

    # Spec AVM-26-03 Table 10.
    RESULT_MESSAGES = {
      'M:' => '欄位未填或格式錯誤',
      'M0' => 'XML 格式錯誤',
      'M1' => 'XML 格式錯誤',
      'C1' => '資料庫發生錯誤',
      'C2' => '資料有誤',
      'C3' => '該發票已過申報期間，需填入核准作廢文號 (return_tax_document_number)',
      'C4' => '無此發票號碼可以作廢',
      'C5' => '該發票已經作廢過',
      'C6' => '作廢資訊已經傳送過',
      'Invalid' => '無效 IP，請通知系統商'
    }.freeze

    def initialize(invoice_number, invoice_year, remark: '退貨', return_tax_document_number: nil)
      raise ArgumentError, 'remark (作廢原因) is required' if remark.to_s.strip.empty?

      @invoice_number = invoice_number
      @invoice_year = invoice_year
      @remark = remark
      @return_tax_document_number = return_tax_document_number
    end

    def execute
      perform
      ResultCode.check!(@response.body[:cancel_invoice_response][:return],
                        RESULT_MESSAGES, success: SUCCESS_CODE)
    end

    private

    def perform
      client = Savon.client(wsdl: Cetustek.config.url, open_timeout: 300, read_timeout: 300)
      @response = client.call(:cancel_invoice, message: {
                                invoicexml: generate_xml,
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

      invoice = Ox::Element.new('Invoice')
      invoice[:XSDVersion] = '2.8'
      doc << invoice

      invoice << raw_tag('InvoiceNumber', @invoice_number)
      invoice << raw_tag('InvoiceYear', @invoice_year)
      # 專案作廢核准文號：只在超過申報期間作廢時才需要 (Table 10 的 C3)。
      invoice << raw_tag('ReturnTaxDocumentNumber', @return_tax_document_number) if @return_tax_document_number
      invoice << raw_tag('Remark', @remark)

      Ox.dump(doc).force_encoding('UTF-8')
    end

    def raw_tag(name, value)
      Ox::Raw.new("<#{name}>#{CGI.escapeHTML(value.to_s)}</#{name}>")
    end
  end
end
