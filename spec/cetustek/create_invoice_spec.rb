# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::CreateInvoice do
  let(:client) { instance_double(Savon::Client) }
  let(:data) { build_invoice_data }

  before do
    Cetustek.configure do |c|
      c.environment = :sandbox
      c.site_id = 'SITE'
      c.username = 'USER'
      c.password = 'PASS'
    end
    allow(Savon).to receive(:client).and_return(client)
    allow(client).to receive(:call)
      .and_return(double('response', body: { create_invoice_v3_response: { return: 'GT68514542;9654' } }))
  end

  it 'sends the built XML with hastax and the encoded credentials' do
    expect(described_class.new(data).execute).to eq({ number: 'GT68514542', random_number: '9654' })

    expect(client).to have_received(:call) do |operation, message:|
      expect(operation).to eq(:create_invoice_v3)
      expect(message[:invoicexml]).to include('<OrderId>ORD1</OrderId>')
      expect(message[:hastax]).to eq(1)
      expect(message[:source]).to eq('SITEPASS')
      expect(message[:rentid]).to eq('USER')
    end
  end

  # ResponseHandler 拿 invoice_data 去記 log 的訂單編號；傳錯東西進去要看得出來
  it 'hands the invoice data to the response handler, so logs carry the order id' do
    logger = instance_double(Logger, info: nil, error: nil, debug: nil)
    Cetustek.config.logger = logger

    described_class.new(data).execute

    expect(logger).to have_received(:info).with('CreateInvoiceV3 ORD1 GT68514542')
  ensure
    Cetustek.config.logger = nil
  end

  it 'passes the order-supplied hastax through' do
    described_class.new(build_invoice_data(hastax: 0)).execute
    expect(client).to have_received(:call) { |_op, message:| expect(message[:hastax]).to eq(0) }
  end
end
