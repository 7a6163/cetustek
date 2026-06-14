# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::QueryInvoiceByOrderId do
  let(:client) { instance_double(Savon::Client) }
  let(:response) { double('response') }

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

  it 'queries by order id with the encoded credentials' do
    described_class.query('ORD1')

    expect(client).to have_received(:call).with(
      :query_invoice_by_orderid,
      message: { orderid: 'ORD1', source: 'SITEPASS', rentid: 'USER' }
    )
  end

  it 'returns the SOAP response' do
    expect(described_class.query('ORD1')).to eq(response)
  end
end
