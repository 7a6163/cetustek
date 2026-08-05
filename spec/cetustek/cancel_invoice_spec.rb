# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::CancelInvoice do
  let(:client) { instance_double(Savon::Client) }

  before do
    Cetustek.configure do |c|
      c.environment = :sandbox
      c.site_id = 'SITE'
      c.username = 'USER'
      c.password = 'PASS'
    end
    allow(Savon).to receive(:client).and_return(client)
  end

  def stub_return(value)
    allow(client).to receive(:call)
      .and_return(double('response', body: { cancel_invoice_response: { return: value } }))
  end

  it 'calls cancel_invoice with the invoice XML and encoded credentials' do
    stub_return('C0')
    expect(described_class.new('AB12345678', 2024, remark: '退貨').execute).to eq('C0')

    expect(client).to have_received(:call) do |operation, message:|
      expect(operation).to eq(:cancel_invoice)
      expect(message[:invoicexml]).to include('<InvoiceNumber>AB12345678</InvoiceNumber>')
      expect(message[:invoicexml]).to include('<InvoiceYear>2024</InvoiceYear>')
      expect(message[:invoicexml]).to include('<Remark>退貨</Remark>')
      expect(message[:source]).to eq('SITEPASS')
      expect(message[:rentid]).to eq('USER')
    end
  end

  it 'omits ReturnTaxDocumentNumber unless the cancellation is past the filing period' do
    stub_return('C0')
    described_class.new('AB12345678', 2024, remark: '退貨').execute
    expect(client).to have_received(:call) do |_op, message:|
      expect(message[:invoicexml]).not_to include('ReturnTaxDocumentNumber')
    end
  end

  it 'sends the 專案作廢核准文號 when given' do
    stub_return('C0')
    described_class.new('AB12345678', 2024, remark: '退貨', return_tax_document_number: '65327645').execute
    expect(client).to have_received(:call) do |_op, message:|
      expect(message[:invoicexml]).to include('<ReturnTaxDocumentNumber>65327645</ReturnTaxDocumentNumber>')
    end
  end

  it 'accepts a custom 作廢原因 and rejects a blank one' do
    stub_return('C0')
    described_class.new('AB12345678', 2024, remark: '明細錯誤').execute
    expect(client).to have_received(:call) { |_op, message:| expect(message[:invoicexml]).to include('明細錯誤') }

    expect { described_class.new('AB12345678', 2024, remark: '') }.to raise_error(ArgumentError, /remark/)
  end

  it 'has no default 作廢原因, since Table 9 makes it 必填' do
    expect { described_class.new('AB12345678', 2024) }.to raise_error(ArgumentError, /remark/)
  end

  it 'rejects a 作廢原因 longer than the 20 characters Table 9 allows' do
    expect { described_class.new('AB12345678', 2024, remark: '原' * 21) }
      .to raise_error(ArgumentError, /20 characters/)
  end

  it 'raises ResultError with the documented message on failure' do
    stub_return('C5')
    expect { described_class.new('AB12345678', 2024, remark: '退貨').execute }
      .to raise_error(Cetustek::ResultError, /C5 - 該發票已經作廢過/)
  end
end
