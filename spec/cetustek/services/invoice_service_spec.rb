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
    described_class.new('<xml/>', 'ORD1').create

    expect(Savon).to have_received(:client).with(
      wsdl: Cetustek.config.url,
      open_timeout: 300,
      read_timeout: 300
    )
  end

  it 'calls create_invoice_v3 with the encoded credentials and hastax' do
    described_class.new('<xml/>', 'ORD1').create

    expect(client).to have_received(:call).with(
      :create_invoice_v3,
      message: { invoicexml: '<xml/>', source: 'SITEPASS', rentid: 'USER', hastax: 1 }
    )
  end

  it 'returns the SOAP response' do
    expect(described_class.new('<xml/>', 'ORD1').create).to eq(response)
  end

  it 'does not log outside a Rails process' do
    expect { described_class.new('<xml/>', 'ORD1').create }.not_to raise_error
  end
end
