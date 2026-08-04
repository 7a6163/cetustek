# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::Services::InvoiceService do
  let(:client) { instance_double(Savon::Client) }
  let(:response) { double('response', body: {}) }

  before do
    Cetustek.configure do |c|
      c.environment = :sandbox
      c.site_id = 'SITE'
      c.username = 'USER'
      c.password = 'PASS'
    end
    allow(Savon).to receive(:client).and_return(client)
    allow(client).to receive(:call).and_return(response)
  end

  it 'builds the Savon client against the configured WSDL with timeouts' do
    described_class.new('<xml/>').create

    expect(Savon).to have_received(:client).with(
      wsdl: Cetustek.config.url,
      open_timeout: 300,
      read_timeout: 300
    )
  end

  it 'calls create_invoice_v3 with the encoded credentials and hastax' do
    described_class.new('<xml/>').create

    expect(client).to have_received(:call).with(
      :create_invoice_v3,
      message: { invoicexml: '<xml/>', source: 'SITEPASS', rentid: 'USER', hastax: 1 }
    )
  end

  it 'sends the hastax supplied by the order (e.g. 0 for tax-exclusive prices)' do
    described_class.new('<xml/>', 0).create
    expect(client).to have_received(:call).with(:create_invoice_v3, message: hash_including(hastax: 0))
  end

  it 'returns the SOAP response' do
    expect(described_class.new('<xml/>').create).to eq(response)
  end
end
