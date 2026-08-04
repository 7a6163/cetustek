# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::Models::InvoiceData do
  describe 'tax defaults' do
    subject(:data) { invoice_data }

    it 'defaults tax_type to taxable (1)' do
      expect(data.tax_type).to eq(Cetustek::TaxType::TAXABLE)
    end

    it 'defaults tax_rate to 0.05' do
      expect(data.tax_rate).to eq(0.05)
    end

    it 'defaults invoice_type to 07' do
      expect(data.invoice_type).to eq('07')
    end

    it 'asks for the JSON return format by default' do
      expect(data.rtn_msg).to eq('Json')
    end

    it 'is not mixed tax by default' do
      expect(data.mixed_tax?).to be(false)
    end
  end

  describe '#mixed_tax?' do
    it 'is true when tax_type is 9' do
      expect(invoice_data(tax_type: 9).mixed_tax?).to be(true)
    end

    it 'is true for the MIXED constant' do
      expect(invoice_data(tax_type: Cetustek::TaxType::MIXED).mixed_tax?).to be(true)
    end
  end

  describe 'carrier codes' do
    it 'mirrors carrier_id into carrier_id2 (手機條碼 has no 顯碼/隱碼 split)' do
      data = invoice_data(donate_mark: 0, carrier_type: '3J0002', carrier_id: '/K.1TI+P',
                          buyer_email: 'a@b.c')
      expect(data.carrier_id1).to eq('/K.1TI+P')
      expect(data.carrier_id2).to eq('/K.1TI+P')
    end

    it 'keeps carrier_id as an alias of carrier_id1' do
      data = invoice_data(donate_mark: 0, carrier_type: '3J0002', carrier_id1: 'X',
                          buyer_email: 'a@b.c')
      expect(data.carrier_id).to eq('X')
    end
  end

  describe 'validation' do
    it 'requires order_id, order_date and items' do
      expect { invoice_data(order_id: nil) }.to raise_error(ArgumentError, /order_id/)
      expect { invoice_data(order_date: nil) }.to raise_error(ArgumentError, /order_date/)
      expect { invoice_data(items: []) }.to raise_error(ArgumentError, /items/)
    end

    it 'rejects an order_date that is not a date' do
      expect { invoice_data(order_date: '2024/01/02') }.to raise_error(ArgumentError, /must be a Date/)
    end

    it 'requires donate_mark and payment_type' do
      expect { invoice_data(donate_mark: nil) }.to raise_error(ArgumentError, /donate_mark/)
      expect { invoice_data(payment_type: nil) }.to raise_error(ArgumentError, /payment_type/)
    end

    it 'rejects an unknown donate_mark' do
      expect { invoice_data(donate_mark: 3) }.to raise_error(ArgumentError, /donate_mark must be/)
    end

    it 'requires email and carrier details when storing to a carrier (donate_mark 0)' do
      expect { invoice_data(donate_mark: 0) }
        .to raise_error(ArgumentError, /buyer_email, carrier_type, carrier_id1 required/)
    end

    it 'requires a 3-7 digit 捐贈碼 when donating (donate_mark 1)' do
      expect { invoice_data(donate_mark: 1) }.to raise_error(ArgumentError, /npo_ban/)
      expect { invoice_data(donate_mark: 1, npo_ban: '12') }.to raise_error(ArgumentError, /npo_ban/)
      expect(invoice_data(donate_mark: 1, npo_ban: '25885').npo_ban).to eq('25885')
    end

    it 'rejects an unknown tax_type' do
      expect { invoice_data(tax_type: 7) }.to raise_error(ArgumentError, /tax_type must be/)
    end

    it 'does not assume 5% for 特種稅率 (tax_type 4)' do
      expect { invoice_data(tax_type: 4, invoice_type: '08') }.to raise_error(ArgumentError, /tax_rate/)
    end

    it 'requires invoice_type 08 for 特種稅率' do
      expect { invoice_data(tax_type: 4, tax_rate: 0.15) }
        .to raise_error(ArgumentError, /invoice_type must be '08'/)
    end

    it 'accepts a fully specified 特種稅額 invoice' do
      data = invoice_data(tax_type: 4, tax_rate: 0.15, invoice_type: '08')
      expect(data.special_tax?).to be(true)
      expect(data.tax_rate).to eq(0.15)
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
