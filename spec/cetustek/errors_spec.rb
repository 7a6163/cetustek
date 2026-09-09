# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::ResultError do
  it 'joins the code and description into the message' do
    error = described_class.new('S7', '訂單號碼已存在')

    expect(error.code).to eq('S7')
    expect(error.message).to eq('S7 - 訂單號碼已存在')
  end

  it 'is just the code when no description is known' do
    error = described_class.new('ZZ')

    expect(error.code).to eq('ZZ')
    expect(error.message).to eq('ZZ')
  end
end

RSpec.describe Cetustek::ResultCode do
  # 帶欄位名的代碼（M:OrderId、D2_3）在表裡只有去掉後綴的那一列，
  # 但整碼命中時必須優先用整碼那一列，別被前綴列蓋過去。
  let(:messages) { { 'M:' => '欄位錯誤', 'M:OrderId' => '訂單編號錯誤', 'S1' => '資料庫發生錯誤' } }

  describe '.describe' do
    it 'prefers the exact row over the suffix-stripped one' do
      expect(described_class.describe('M:OrderId', messages)).to eq('訂單編號錯誤')
    end

    it 'falls back to the table row without the suffix' do
      expect(described_class.describe('M:BuyerName', messages)).to eq('欄位錯誤')
    end

    it 'looks a plain code up as-is' do
      expect(described_class.describe('S1', messages)).to eq('資料庫發生錯誤')
    end

    it 'is nil for a code no table row covers' do
      expect(described_class.describe('ZZ', messages)).to be_nil
    end
  end

  describe '.check!' do
    it 'returns the code untouched on success' do
      expect(described_class.check!('A0', messages, success: 'A0')).to eq('A0')
    end

    it 'raises with the documented description on anything else' do
      expect { described_class.check!('S1', messages, success: 'A0') }
        .to raise_error(Cetustek::ResultError, 'S1 - 資料庫發生錯誤') { |e| expect(e.code).to eq('S1') }
    end
  end
end
