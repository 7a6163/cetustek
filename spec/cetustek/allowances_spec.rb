# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Allowances' do
  let(:client) { instance_double(Savon::Client) }

  before do
    Cetustek.configure do |c|
      c.environment = :sandbox
      c.site_id = 'SITE'
      c.username = 'USER'
      c.password = 'PASS'
    end
    allow(Savon).to receive(:client).and_return(client)
  end

  def stub_return(key, value)
    allow(client).to receive(:call).and_return(double('response', body: { key => { return: value } }))
  end

  describe Cetustek::CreateAllowance do
    let(:data) do
      Cetustek::Models::AllowanceData.new(
        allowance_number: 'AA20130214163520',
        allowance_date: Date.new(2024, 2, 16),
        invoice_number: 'AA10000000',
        invoice_year: '2024',
        tax_type: 1,
        reason: '退回',
        items: [
          Cetustek::Models::InvoiceItem.new(code: '0001', name: '禮券', quantity: 1, unit: '本', unit_price: 800)
        ]
      )
    end

    it 'returns the result code (A0 = success)' do
      stub_return(:create_allowance_response, 'A0')
      expect(described_class.new(data).execute).to eq('A0')
    end

    it 'sends create_allowance with checkallowance and a valid allowance XML' do
      stub_return(:create_allowance_response, 'A0')
      described_class.new(data, check_allowance: 1).execute

      expect(client).to have_received(:call) do |operation, message:|
        expect(operation).to eq(:create_allowance)
        expect(message[:checkallowance]).to eq(1)
        expect(message[:source]).to eq('SITEPASS')
        xml = message[:allowancexml]
        expect(xml).to include('<AllowanceNumber>AA20130214163520</AllowanceNumber>')
        expect(xml).to include('<AllowanceDate>2024/02/16</AllowanceDate>')
        expect(xml).to include('<Unit>本</Unit>')
        expect(xml).to include('<UnitPrice>800</UnitPrice>')
      end
    end

    it 'omits RoundNum when not provided' do
      stub_return(:create_allowance_response, 'A0')
      described_class.new(data).execute
      expect(client).to have_received(:call) { |_op, message:| expect(message[:allowancexml]).not_to include('RoundNum') }
    end
  end

  describe Cetustek::CancelAllowance do
    it 'returns the result code (C0 = success) and sends the cancel XML' do
      stub_return(:cancel_allowance_response, 'C0')
      result = described_class.new('AA20130214163520', '明細錯誤').execute

      expect(result).to eq('C0')
      expect(client).to have_received(:call) do |operation, message:|
        expect(operation).to eq(:cancel_allowance)
        expect(message[:allowancexml]).to include('<AllowanceNumber>AA20130214163520</AllowanceNumber>')
        expect(message[:allowancexml]).to include('<Reason>明細錯誤</Reason>')
      end
    end
  end
end
