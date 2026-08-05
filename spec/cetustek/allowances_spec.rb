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
      build_allowance_data(
        allowance_number: 'AA20130214163520',
        allowance_date: Date.new(2024, 2, 16),
        invoice_number: 'AA10000000',
        reason: '退回',
        items: [build_invoice_item(code: '0001', name: '禮券', unit: '本', unit_price: 800)]
      )
    end

    it 'returns the result code (A0 = success)' do
      stub_return(:create_allowance_response, 'A0')
      expect(described_class.new(data).execute).to eq('A0')
    end

    it 'sends create_allowance with checkallowance and a valid allowance XML' do
      stub_return(:create_allowance_response, 'A0')
      described_class.new(data).execute

      expect(client).to have_received(:call) do |operation, message:|
        expect(operation).to eq(:create_allowance)
        expect(message[:checkallowance]).to eq(0)
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

    it 'rejects the removed unconfirmed-allowance flag' do
      expect { described_class.new(data, check_allowance: 1) }.to raise_error(ArgumentError, /check_allowance/)
    end

    it 'raises ResultError with the documented message on failure' do
      stub_return(:create_allowance_response, 'A2')
      expect { described_class.new(data).execute }
        .to raise_error(Cetustek::ResultError, /A2 - 所有折讓金額加總不能大於原發票金額/) { |e| expect(e.code).to eq('A2') }
    end

    it 'resolves suffixed result codes to their prefix message' do
      stub_return(:create_allowance_response, 'D2_3')
      expect { described_class.new(data).execute }
        .to raise_error(Cetustek::ResultError, /D2_3 - 數量未填或格式錯誤/)
    end
  end

  describe Cetustek::CancelAllowance do
    it 'requires both Table 18 fields' do
      expect { described_class.new('', '明細錯誤') }.to raise_error(ArgumentError, /allowance_number/)
      expect { described_class.new('AA20130214163520', nil) }.to raise_error(ArgumentError, /reason/)
      expect { described_class.new('AA20130214163520', '因' * 21) }.to raise_error(ArgumentError, /20 characters/)
    end

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

    it 'raises ResultError with the documented message on failure' do
      stub_return(:cancel_allowance_response, 'C2')
      expect { described_class.new('AA20130214163520', '明細錯誤').execute }
        .to raise_error(Cetustek::ResultError, /C2 - 折讓單已申報，無法作廢/)
    end
  end

  describe Cetustek::Models::AllowanceData do
    it 'rejects tax types the allowance spec does not allow' do
      expect { build_allowance_data(tax_type: 9) }
        .to raise_error(ArgumentError, /tax_type must be 1/)
    end

    it 'accepts 零稅率 and 免稅' do
      expect(build_allowance_data(tax_type: 2).tax_type).to eq(2)
      expect(build_allowance_data(tax_type: '3').tax_type).to eq('3')
    end

    it 'requires the fields Table 15 marks 必填' do
      expect { build_allowance_data(allowance_number: nil) }.to raise_error(ArgumentError, /allowance_number/)
      expect { build_allowance_data(invoice_number: nil) }.to raise_error(ArgumentError, /invoice_number/)
      expect { build_allowance_data(invoice_year: '') }.to raise_error(ArgumentError, /invoice_year/)
      expect { build_allowance_data(reason: nil) }.to raise_error(ArgumentError, /reason/)
      expect { build_allowance_data(items: []) }.to raise_error(ArgumentError, /items/)
    end

    it 'rejects an allowance_date that is not a date, instead of failing at XML build time' do
      expect { build_allowance_data(allowance_date: nil) }.to raise_error(ArgumentError, /allowance_date/)
      expect { build_allowance_data(allowance_date: '2024/02/16') }
        .to raise_error(ArgumentError, /must be a Date/)
    end

    it 'holds 折讓原因 to the 20 characters Table 15 allows' do
      expect { build_allowance_data(reason: '因' * 21) }.to raise_error(ArgumentError, /20 characters/)
    end

    it 'rejects a round_num outside the documented 0-7 range' do
      expect { build_allowance_data(round_num: 8) }.to raise_error(ArgumentError, /round_num/)
      expect(build_allowance_data(round_num: 0).round_num).to eq(0)
    end
  end
end
