# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::CancelInvoice do
  let(:client) { instance_double(Savon::Client) }
  let(:invoice) { double('invoice', number: 'AB12345678', created_at: Date.new(2024, 1, 2)) }

  before do
    Cetustek.configure do |c|
      c.environment = :sandbox
      c.site_id = 'SITE'
      c.username = 'USER'
      c.password = 'PASS'
    end
    allow(Savon).to receive(:client).and_return(client)
    allow(invoice).to receive(:update)
  end

  def stub_return(value)
    allow(client).to receive(:call)
      .and_return(double('response', body: { cancel_invoice_response: { return: value } }))
  end

  it 'calls cancel_invoice with the invoice XML and encoded credentials' do
    stub_return('C0')
    described_class.new(invoice).execute

    expect(client).to have_received(:call) do |operation, message:|
      expect(operation).to eq(:cancel_invoice)
      expect(message[:invoicexml]).to include('<InvoiceNumber>AB12345678</InvoiceNumber>')
      expect(message[:invoicexml]).to include('<InvoiceYear>2024</InvoiceYear>')
      expect(message[:source]).to eq('SITEPASS')
      expect(message[:rentid]).to eq('USER')
    end
  end

  it 'marks the invoice canceled when the return code is C0' do
    stub_return('C0')
    described_class.new(invoice).execute
    expect(invoice).to have_received(:update).with(canceled: true)
  end

  it 'does not mark the invoice canceled for any other return code' do
    stub_return('C5')
    described_class.new(invoice).execute
    expect(invoice).not_to have_received(:update)
  end
end
