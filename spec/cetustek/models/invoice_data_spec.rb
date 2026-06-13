# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::Models::InvoiceData do
  describe 'tax defaults' do
    subject(:data) { described_class.new }

    it 'defaults tax_type to taxable (1)' do
      expect(data.tax_type).to eq(Cetustek::TaxType::TAXABLE)
    end

    it 'defaults tax_rate to 0.05' do
      expect(data.tax_rate).to eq(0.05)
    end

    it 'defaults invoice_type to 07' do
      expect(data.invoice_type).to eq('07')
    end

    it 'is not mixed tax by default' do
      expect(data.mixed_tax?).to be(false)
    end
  end

  describe '#mixed_tax?' do
    it 'is true when tax_type is 9' do
      expect(described_class.new(tax_type: 9).mixed_tax?).to be(true)
    end

    it 'is true for the MIXED constant' do
      expect(described_class.new(tax_type: Cetustek::TaxType::MIXED).mixed_tax?).to be(true)
    end
  end
end

RSpec.describe Cetustek::Models::InvoiceItem do
  describe '#d_type' do
    it 'maps :taxable (default) to a blank string' do
      item = described_class.new(code: 'A', name: 'n', quantity: 1, unit_price: 1)
      expect(item.d_type).to eq('')
    end

    it 'maps :zero_rate to TZ' do
      item = described_class.new(code: 'A', name: 'n', quantity: 1, unit_price: 1, tax_type: :zero_rate)
      expect(item.d_type).to eq('TZ')
    end

    it 'maps :tax_free to TN' do
      item = described_class.new(code: 'A', name: 'n', quantity: 1, unit_price: 1, tax_type: :tax_free)
      expect(item.d_type).to eq('TN')
    end

    it 'passes through raw codes' do
      item = described_class.new(code: 'A', name: 'n', quantity: 1, unit_price: 1, tax_type: 'TN')
      expect(item.d_type).to eq('TN')
    end
  end
end
