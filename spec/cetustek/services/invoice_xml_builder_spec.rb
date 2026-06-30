# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::Services::InvoiceXmlBuilder do
  def build(overrides = {})
    items = overrides.delete(:items) || [
      Cetustek::Models::InvoiceItem.new(code: 'A1', name: 'Item', quantity: 1, unit_price: 100)
    ]
    data = Cetustek::Models::InvoiceData.new({
      order_id: 'ORD1',
      order_date: Date.new(2024, 1, 2),
      buyer_identifier: '12345678',
      buyer_name: 'Buyer',
      buyer_email: 'buyer@example.com',
      items: items
    }.merge(overrides))
    described_class.new(data).build
  end

  describe 'TaxType' do
    it 'defaults to taxable (1) when not specified' do
      expect(build).to include('<TaxType>1</TaxType>')
    end

    it 'emits zero-rate (2) when configured' do
      expect(build(tax_type: 2)).to include('<TaxType>2</TaxType>')
    end

    it 'emits mixed tax (9) when configured' do
      expect(build(tax_type: 9)).to include('<TaxType>9</TaxType>')
    end
  end

  describe 'TaxRate' do
    it 'defaults to 0.05' do
      expect(build).to include('<TaxRate>0.05</TaxRate>')
    end

    it 'honors an explicit rate (e.g. 0 for zero-rate)' do
      expect(build(tax_type: 2, tax_rate: 0)).to include('<TaxRate>0</TaxRate>')
    end
  end

  describe 'PayWay' do
    it 'passes the payment_type code through to <PayWay>' do
      expect(build(payment_type: Cetustek::PayWay::LINE_PAY)).to include('<PayWay>L</PayWay>')
    end
  end

  describe 'DonateMark' do
    it 'passes the donate_mark code through to <DonateMark>' do
      expect(build(donate_mark: Cetustek::DonateMark::DONATE)).to include('<DonateMark>1</DonateMark>')
    end
  end

  describe 'InvoiceType' do
    it 'defaults to 07 (general)' do
      expect(build).to include('<InvoiceType>07</InvoiceType>')
    end

    it 'can be overridden to 08 (special tax)' do
      expect(build(invoice_type: '08')).to include('<InvoiceType>08</InvoiceType>')
    end
  end

  describe 'DType (per-item tax category, mixed mode only)' do
    let(:mixed_items) do
      [
        Cetustek::Models::InvoiceItem.new(code: 'A', name: 'Taxable', quantity: 1, unit_price: 100),
        Cetustek::Models::InvoiceItem.new(code: 'B', name: 'Zero', quantity: 1, unit_price: 100, tax_type: :zero_rate),
        Cetustek::Models::InvoiceItem.new(code: 'C', name: 'Free', quantity: 1, unit_price: 100, tax_type: :tax_free)
      ]
    end

    it 'omits DType entirely when not mixed tax' do
      expect(build(tax_type: 1, items: mixed_items)).not_to include('<DType>')
    end

    it 'emits DType for every product item when mixed tax' do
      xml = build(tax_type: 9, items: mixed_items)
      expect(xml).to include('<DType></DType>') # taxable -> blank
      expect(xml).to include('<DType>TZ</DType>') # zero-rate
      expect(xml).to include('<DType>TN</DType>') # tax-free
    end

    it 'accepts raw DType codes as well as symbols' do
      items = [Cetustek::Models::InvoiceItem.new(code: 'A', name: 'Z', quantity: 1, unit_price: 1, tax_type: 'TZ')]
      expect(build(tax_type: 9, items: items)).to include('<DType>TZ</DType>')
    end
  end

  describe 'XML escaping' do
    it 'escapes special characters in buyer name' do
      expect(build(buyer_name: 'A & B <Co>')).to include('<BuyerName>A &amp; B &lt;Co&gt;</BuyerName>')
    end

    it 'escapes special characters in order id and other plain fields' do
      xml = build(order_id: 'A&B<1>')
      expect(xml).to include('<OrderId>A&amp;B&lt;1&gt;</OrderId>')
    end

    it 'escapes special characters in product code and description' do
      items = [Cetustek::Models::InvoiceItem.new(code: 'C&<1>', name: 'N&<2>', quantity: 1, unit_price: 1)]
      xml = build(items: items)
      expect(xml).to include('<ProductionCode>C&amp;&lt;1&gt;</ProductionCode>')
      expect(xml).to include('<Description>N&amp;&lt;2&gt;</Description>')
    end

    it 'does not double-escape (no &amp;amp;)' do
      expect(build(buyer_name: 'A & B')).not_to include('&amp;amp;')
    end
  end

  describe 'detail lines (API-faithful, no app-specific conveniences)' do
    it 'emits only the caller-supplied product items, with no auto-generated lines' do
      xml = build
      %w[DISCOUNT COUPON DELIVERY_FEE HANDLING_FEE].each do |code|
        expect(xml).not_to include(code)
      end
      expect(xml.scan('<ProductItem>').size).to eq(1)
    end

    it 'lets callers model a discount as their own negative-priced item' do
      items = [
        Cetustek::Models::InvoiceItem.new(code: 'A', name: 'Item', quantity: 1, unit_price: 100),
        Cetustek::Models::InvoiceItem.new(code: 'DISCOUNT', name: '折抵', quantity: 1, unit_price: -30)
      ]
      xml = build(items: items)
      expect(xml.scan('<ProductItem>').size).to eq(2)
      expect(xml).to include('<UnitPrice>-30</UnitPrice>')
    end
  end
end
