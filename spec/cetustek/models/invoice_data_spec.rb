# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::Models::InvoiceData do
  describe 'tax defaults' do
    subject(:data) { build_invoice_data }

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
      expect(build_invoice_data(tax_type: 9).mixed_tax?).to be(true)
    end

    it 'is true for the MIXED constant' do
      expect(build_invoice_data(tax_type: Cetustek::TaxType::MIXED).mixed_tax?).to be(true)
    end

    it 'is true when tax_type arrives as the string "9"' do
      expect(build_invoice_data(tax_type: '9').mixed_tax?).to be(true)
    end
  end

  describe 'optional buyer fields' do
    it 'keeps every 選填 買受人欄位 the caller passes' do
      attrs = { buyer_identifier: '12345678', buyer_name: '買方', buyer_email: 'a@b.c',
                buyer_address: '台北市', buyer_person_in_charge: '負責人',
                buyer_telephone: '0212345678', buyer_facsimile: '0287654321',
                buyer_customer_number: 'C001' }
      data = build_invoice_data(attrs)

      expect(attrs.keys.to_h { |k| [k, data.public_send(k)] }).to eq(attrs)
    end
  end

  describe 'carrier codes' do
    it 'mirrors carrier_id into carrier_id2 for carriers with no 顯碼/隱碼 split' do
      [Cetustek::CarrierType::MOBILE_BARCODE, Cetustek::CarrierType::CITIZEN_CERT].each do |type|
        data = build_invoice_data(donate_mark: 0, carrier_type: type, carrier_id: '/K.1TI+P',
                                  buyer_email: 'a@b.c')
        expect(data.carrier_id1).to eq('/K.1TI+P')
        expect(data.carrier_id2).to eq('/K.1TI+P')
      end
    end

    it 'refuses to guess 隱碼 for a 會員載具, where the two codes differ' do
      expect do
        build_invoice_data(donate_mark: 0, carrier_type: Cetustek::CarrierType::CETUSTEK_CARD,
                           carrier_id: 'L9GSe', buyer_email: 'a@b.c')
      end.to raise_error(ArgumentError, /carrier_id2 required.*顯碼與隱碼/)
    end

    it 'matches the carrier constant even when carrier_type is a symbol' do
      data = build_invoice_data(donate_mark: 0, carrier_type: :'3J0002', carrier_id: '/K.1TI+P',
                                buyer_email: 'a@b.c')
      expect(data.carrier_id2).to eq('/K.1TI+P')
    end

    it 'keeps carrier_id as an alias of carrier_id1' do
      data = build_invoice_data(donate_mark: 0, carrier_type: Cetustek::CarrierType::MOBILE_BARCODE,
                                carrier_id1: 'X', buyer_email: 'a@b.c')
      expect(data.carrier_id).to eq('X')
    end
  end

  describe 'validation' do
    it 'requires order_id, order_date and items' do
      expect { build_invoice_data(order_id: nil) }.to raise_error(ArgumentError, /order_id/)
      expect { build_invoice_data(order_date: nil) }.to raise_error(ArgumentError, /order_date is required/)
      expect { build_invoice_data(items: []) }.to raise_error(ArgumentError, /items/)
    end

    it 'rejects an order_date that is not a date' do
      expect { build_invoice_data(order_date: '2024/01/02') }
        .to raise_error(ArgumentError, /must be a Date or Time, got String/)
    end

    it 'requires donate_mark and payment_type' do
      expect { build_invoice_data(donate_mark: nil) }.to raise_error(ArgumentError, /donate_mark is required/)
      expect { build_invoice_data(payment_type: nil) }.to raise_error(ArgumentError, /payment_type is required/)
    end

    it 'rejects an unknown donate_mark' do
      expect { build_invoice_data(donate_mark: 3) }
        .to raise_error(ArgumentError, /donate_mark must be 0 \(載具\), 1 \(捐贈\) or 2 \(紙本\), got 3/)
    end

    it 'requires email and both carrier codes when storing to a carrier (donate_mark 0)' do
      expect { build_invoice_data(donate_mark: 0) }
        .to raise_error(ArgumentError, /buyer_email, carrier_id1, carrier_id2 required/)
    end

    it 'accepts a blank carrier_type, which is how 鯨躍發票卡 is requested' do
      data = build_invoice_data(donate_mark: 0, buyer_email: 'a@b.c', carrier_id1: 'shown', carrier_id2: 'hidden')
      expect(data.carrier_type).to be_nil
    end

    it 'only allows mail_send on carrier invoices' do
      expect { build_invoice_data(mail_send: 1) }.to raise_error(ArgumentError, /mail_send/)
    end

    it 'only allows zero_reason on zero-rate invoices (tax_type 2 or 5)' do
      expect { build_invoice_data(zero_reason: '71') }.to raise_error(ArgumentError, /zero_reason/)
      expect(build_invoice_data(tax_type: 5, zero_reason: '71').zero_reason).to eq('71')
    end

    it 'rejects a round_num outside the documented 0-7 range' do
      expect { build_invoice_data(round_num: 8) }.to raise_error(ArgumentError, /round_num/)
    end

    it 'accepts every round_num in the documented 0-7 range' do
      expect((0..7).map { |n| build_invoice_data(round_num: n).round_num }).to eq((0..7).to_a)
    end

    it 'holds remark to the 200 characters Table 1 allows' do
      expect { build_invoice_data(remark: '註' * 201) }.to raise_error(ArgumentError, /200 characters/)
    end

    it 'accepts a remark of exactly 200 characters' do
      expect(build_invoice_data(remark: '註' * 200).remark.length).to eq(200)
    end

    it "rejects more than #{Cetustek::Models::InvoiceData::MAX_ITEMS} 明細 lines" do
      items = Array.new(Cetustek::Models::InvoiceData::MAX_ITEMS + 1, build_invoice_item)
      expect { build_invoice_data(items: items) }.to raise_error(ArgumentError, /must not exceed 9999 lines/)
    end

    it 'treats a whitespace-only 必填 field as missing' do
      expect { build_invoice_data(order_id: '   ') }.to raise_error(ArgumentError, /order_id is required/)
      expect { build_invoice_data(payment_type: ' ') }.to raise_error(ArgumentError, /payment_type is required/)
      expect { build_invoice_data(donate_mark: '') }.to raise_error(ArgumentError, /donate_mark is required/)
    end

    it 'requires attributes at all' do
      expect { described_class.new }.to raise_error(ArgumentError, /order_id is required/)
    end

    it 'requires a 3-7 digit 捐贈碼 when donating (donate_mark 1)' do
      expect { build_invoice_data(donate_mark: 1) }.to raise_error(ArgumentError, /npo_ban/)
      expect { build_invoice_data(donate_mark: 1, npo_ban: '12') }.to raise_error(ArgumentError, /got "12"/)
      expect(build_invoice_data(donate_mark: 1, npo_ban: '25885').npo_ban).to eq('25885')
    end

    it 'rejects an unknown tax_type' do
      expect { build_invoice_data(tax_type: 7) }
        .to raise_error(ArgumentError, /tax_type must be one of 1, 2, 3, 4, 5, 9, got 7/)
    end

    # 'x'.to_i 是 0，而 0 是「載具」「四捨五入」的有效代碼：用 to_i 比對的話，
    # 亂填的代碼會被當成 0 靜靜開出去，而不是擋在這裡。
    it 'rejects a non-numeric 代碼 instead of letting to_i turn it into 0' do
      expect { build_invoice_data(tax_type: 'x') }.to raise_error(ArgumentError, /tax_type must be one of/)
      expect { build_invoice_data(donate_mark: 'x') }.to raise_error(ArgumentError, /donate_mark must be 0/)
      expect { build_invoice_data(round_num: 'x') }.to raise_error(ArgumentError, /round_num must be between/)
    end

    it 'accepts tax_type as a string, the way a form or ENV hands it over' do
      expect(build_invoice_data(tax_type: '1').tax_type).to eq('1')
      expect(build_invoice_data(tax_type: '9').mixed_tax?).to be(true)
      expect(build_invoice_data(tax_type: '5', zero_reason: '71').zero_reason).to eq('71')
      expect { build_invoice_data(tax_type: '7') }.to raise_error(ArgumentError, /tax_type must be/)
    end

    it 'does not assume 5% for 特種稅率 (tax_type 4)' do
      expect { build_invoice_data(tax_type: 4, invoice_type: '08') }.to raise_error(ArgumentError, /tax_rate/)
    end

    it 'requires invoice_type 08 for 特種稅率' do
      expect { build_invoice_data(tax_type: 4, tax_rate: 0.15) }
        .to raise_error(ArgumentError, /invoice_type must be '08'/)
    end

    it 'accepts a fully specified 特種稅額 invoice' do
      data = build_invoice_data(tax_type: 4, tax_rate: 0.15, invoice_type: '08')
      expect(data.special_tax?).to be(true)
      expect(data.tax_rate).to eq(0.15)
    end

    it 'recognises 特種稅率 given as a string' do
      data = build_invoice_data(tax_type: '4', tax_rate: 0.15, invoice_type: '08')
      expect(data.special_tax?).to be(true)
      expect(data.tax_rate).to eq(0.15)
    end
  end
end

RSpec.describe Cetustek::Models::InvoiceItem do
  describe 'validation' do
    it 'requires the four fields Table 2/16 mark 必填' do
      expect { build_invoice_item(code: nil) }.to raise_error(ArgumentError, /code/)
      expect { build_invoice_item(name: '') }.to raise_error(ArgumentError, /name/)
      expect { build_invoice_item(quantity: nil) }.to raise_error(ArgumentError, /quantity/)
      expect { build_invoice_item(unit_price: nil) }.to raise_error(ArgumentError, /unit_price/)
    end

    it 'leaves 單位 optional' do
      expect(build_invoice_item(unit: nil).unit).to be_nil
    end
  end

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
