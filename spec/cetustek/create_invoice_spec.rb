# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::CreateInvoice do
  let(:invoice_data) { Cetustek::Models::InvoiceData.new(order_id: 'ORD1') }
  let(:response) { double('response') }
  let(:result) { { number: 'GT68514542', random_number: '9654' } }

  before do
    builder = instance_double(Cetustek::Services::InvoiceXmlBuilder, build: '<xml/>')
    allow(Cetustek::Services::InvoiceXmlBuilder).to receive(:new).with(invoice_data).and_return(builder)

    service = instance_double(Cetustek::Services::InvoiceService, create: response)
    allow(Cetustek::Services::InvoiceService).to receive(:new).with('<xml/>', 'ORD1').and_return(service)

    handler = instance_double(Cetustek::Services::ResponseHandler, process: result)
    allow(Cetustek::Services::ResponseHandler).to receive(:new)
      .with(response, invoice_data, '<xml/>').and_return(handler)
  end

  it 'wires builder -> service -> handler and returns the result' do
    expect(described_class.new(invoice_data).execute).to eq(result)
  end

  it 'does not attempt the Rails invoice_info update outside Rails' do
    # Rails is undefined in the test environment, so the guard must short-circuit.
    expect(invoice_data).not_to respond_to(:invoice_info)
    expect { described_class.new(invoice_data).execute }.not_to raise_error
  end
end
