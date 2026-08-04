# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::Services::ResponseHandler do
  let(:data) { invoice_data }

  def response_with(return_value)
    double('response', body: { create_invoice_v3_response: { return: return_value } })
  end

  def process(return_value)
    described_class.new(response_with(return_value), data).process
  end

  describe 'Table 8 JSON return (RtnMsg=Json)' do
    let(:json) do
      '{"msg":"Success","invnumber":"WB02100001","invdate":"2026/02/10","invtime":"11:19:57",' \
        '"random":"3690","ctkurl":"Zm9v","saleamt":666,"zeroamt":0,"freeamt":0,"taxamt":0,"totalamt":666}'
    end

    it 'returns the issued invoice with the platform-assigned date and amounts' do
      expect(process(json)).to eq(
        number: 'WB02100001', random_number: '3690', date: '2026/02/10', time: '11:19:57',
        sale_amount: 666, zero_amount: 0, free_amount: 0, tax_amount: 0, total_amount: 666,
        carrier_url: 'Zm9v'
      )
    end

    it 'raises with the documented reason when msg is a result code' do
      expect { process('{"msg":"S7"}') }
        .to raise_error(Cetustek::ResultError, /S7 - 訂單號碼已存在/) { |e| expect(e.code).to eq('S7') }
    end
  end

  describe 'plain string return' do
    it 'accepts the documented 15-character 發票號碼;隨機碼 form' do
      expect(process('GT68514542;9654')).to eq(number: 'GT68514542', random_number: '9654')
    end

    it 'rejects a semicolon string that is not 15 characters' do
      expect { process('GT685145;9654') }.to raise_error(Cetustek::ResultError)
    end
  end

  describe 'result codes' do
    it 'maps Table 7 codes to their documented message' do
      expect { process('S2') }.to raise_error(Cetustek::ResultError, /S2 - 訂單日期超過開立日期/)
      expect { process('M1') }.to raise_error(Cetustek::ResultError, /M1 - XML 格式錯誤/)
      expect { process('Invalid') }.to raise_error(Cetustek::ResultError, /Invalid - 無效 IP/)
    end

    it 'resolves suffixed codes to their prefix message' do
      expect { process('D3_2') }.to raise_error(Cetustek::ResultError, /D3_2 - 單價未填或格式錯誤/)
      expect { process('M:OrderId') }.to raise_error(Cetustek::ResultError, /M:OrderId - 欄位未填或格式錯誤/)
    end

    it 'still raises the pre-0.7 error class' do
      expect { process('S1') }.to raise_error(described_class::InvalidResponseError)
    end
  end

  describe 'logging' do
    let(:logger) { instance_double(Logger, info: nil, error: nil, debug: nil) }

    before { Cetustek.config.logger = logger }
    after { Cetustek.config.logger = nil }

    it 'logs the order id and invoice number on success, without the response body' do
      process('GT68514542;9654')
      expect(logger).to have_received(:info).with('CreateInvoiceV3 ORD1 GT68514542')
    end

    it 'logs the failing code and the XML only on failure' do
      expect { described_class.new(response_with('S1'), data, '<Invoice/>').process }
        .to raise_error(Cetustek::ResultError)
      expect(logger).to have_received(:error).with('CreateInvoiceV3 ORD1 S1')
      expect(logger).to have_received(:debug).with('<Invoice/>')
    end
  end
end
