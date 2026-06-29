# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SOAP queries' do
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

  describe Cetustek::QueryInvoice do
    it 'queries by invoice number and year' do
      expect(described_class.query('AB12345678', '2024')).to eq(response)
      expect(client).to have_received(:call).with(
        :query_invoice,
        message: { invoicenumber: 'AB12345678', invoiceyear: '2024', source: 'SITEPASS', rentid: 'USER' }
      )
    end
  end

  describe Cetustek::QueryInvoiceNumberByOrderId do
    it 'queries the invoice number by order id' do
      described_class.query('ORD1')
      expect(client).to have_received(:call).with(
        :query_invoice_number_by_orderid,
        message: { orderid: 'ORD1', source: 'SITEPASS', rentid: 'USER' }
      )
    end
  end

  describe Cetustek::QueryAllowance do
    it 'queries by allowance number' do
      described_class.query('AA1411210027')
      expect(client).to have_received(:call).with(
        :query_allowance,
        message: { allowancenumber: 'AA1411210027', source: 'SITEPASS', rentid: 'USER' }
      )
    end
  end
end
