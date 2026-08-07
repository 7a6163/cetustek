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

  describe '.find' do
    it 'parses the response via Table 13, same as QueryInvoice.find' do
      xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <Invoice XSDVersion="2.8">
          <OrderID>ORD1</OrderID>
          <InvoiceNumber>AA00000027</InvoiceNumber>
        </Invoice>
      XML
      allow(response).to receive(:body).and_return({ query_invoice_by_orderid_response: { return: xml } })

      expect(described_class.find('ORD1')).to include(order_id: 'ORD1', invoice_number: 'AA00000027')
    end

    it 'returns nil for the documented "nodata"' do
      allow(response).to receive(:body).and_return({ query_invoice_by_orderid_response: { return: 'nodata' } })

      expect(described_class.find('ORD1')).to be_nil
    end
  end
end
