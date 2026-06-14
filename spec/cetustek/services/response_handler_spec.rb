# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::Services::ResponseHandler do
  let(:invoice_data) { Cetustek::Models::InvoiceData.new(order_id: 'ORD1') }

  def response_with(return_value)
    double('response', body: { create_invoice_v3_response: { return: return_value } })
  end

  it 'splits the return string into number and random number' do
    result = described_class.new(response_with('GT68514542;9654'), invoice_data).process
    expect(result).to eq(number: 'GT68514542', random_number: '9654')
  end

  it 'raises InvalidResponseError when the return has no random number' do
    expect do
      described_class.new(response_with('S2'), invoice_data).process
    end.to raise_error(described_class::InvalidResponseError, /Invalid response: S2/)
  end
end
