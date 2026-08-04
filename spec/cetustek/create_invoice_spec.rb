# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::CreateInvoice do
  let(:data) { invoice_data }
  let(:response) { double('response') }
  let(:result) { { number: 'GT68514542', random_number: '9654' } }

  before do
    builder = instance_double(Cetustek::Services::InvoiceXmlBuilder, build: '<xml/>')
    allow(Cetustek::Services::InvoiceXmlBuilder).to receive(:new).with(data).and_return(builder)

    service = instance_double(Cetustek::Services::InvoiceService, create: response)
    allow(Cetustek::Services::InvoiceService).to receive(:new).with('<xml/>', 1).and_return(service)

    handler = instance_double(Cetustek::Services::ResponseHandler, process: result)
    allow(Cetustek::Services::ResponseHandler).to receive(:new)
      .with(response, data, '<xml/>').and_return(handler)
  end

  it 'wires builder -> service -> handler and returns the result' do
    expect(described_class.new(data).execute).to eq(result)
  end
end
