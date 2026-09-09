# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::Services::InvoiceXmlBuilder do
  def build(overrides = {})
    data = build_invoice_data({
      buyer_identifier: '12345678',
      buyer_name: 'Buyer',
      buyer_email: 'buyer@example.com'
    }.merge(overrides))
    described_class.new(data).build
  end

  # 一張全欄位發票的完整輸出：欄位名稱、順序與 Table 1 對照，少一個欄位或
  # 順序跑掉這裡就會紅，比一堆 include 更擋得住。
  describe 'the full Table 1/2 document' do
    it 'emits every field the platform expects, in spec order' do
      item = Cetustek::Models::InvoiceItem.new(code: '0001', name: '禮券', quantity: 2,
                                               unit: '本', unit_price: 400)
      xml = build(
        buyer_address: '台北市', buyer_person_in_charge: '負責人', buyer_name: '買方',
        buyer_telephone: '0212345678', buyer_facsimile: '0287654321', buyer_customer_number: 'C001',
        donate_mark: 0, carrier_type: Cetustek::CarrierType::MOBILE_BARCODE, carrier_id: '/K.1TI+P',
        npo_ban: '25885', tax_type: 2, tax_rate: 0, zero_reason: '71', payment_type: 'L',
        remark: '備註', mail_send: 1, round_num: 2, items: [item]
      )

      expect(xml).to eq(<<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <Invoice XSDVersion="2.8">
          <OrderId>ORD1</OrderId>
          <OrderDate>2024/01/02</OrderDate>
          <BuyerIdentifier>12345678</BuyerIdentifier>
          <BuyerName>買方</BuyerName>
          <BuyerAddress>台北市</BuyerAddress>
          <BuyerPersonInCharge>負責人</BuyerPersonInCharge>
          <BuyerTelephoneNumber>0212345678</BuyerTelephoneNumber>
          <BuyerFacsimileNumber>0287654321</BuyerFacsimileNumber>
          <BuyerEmailAddress>buyer@example.com</BuyerEmailAddress>
          <BuyerCustomerNumber>C001</BuyerCustomerNumber>
          <DonateMark>0</DonateMark>
          <InvoiceType>07</InvoiceType>
          <CarrierType>3J0002</CarrierType>
          <CarrierId1>/K.1TI+P</CarrierId1>
          <CarrierId2>/K.1TI+P</CarrierId2>
          <NPOBAN>25885</NPOBAN>
          <TaxType>2</TaxType>
          <TaxRate>0</TaxRate>
          <ZeroReason>71</ZeroReason>
          <PayWay>L</PayWay>
          <Remark>備註</Remark>
          <MailSend>1</MailSend>
          <RoundNum>2</RoundNum>
          <RtnMsg>Json</RtnMsg>
          <Details>
            <ProductItem>
              <ProductionCode>0001</ProductionCode>
              <Description>禮券</Description>
              <Quantity>2</Quantity>
              <Unit>本</Unit>
              <UnitPrice>400</UnitPrice>
            </ProductItem>
          </Details>
        </Invoice>
      XML
    end
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
      xml = build(donate_mark: Cetustek::DonateMark::DONATE, npo_ban: '25885')
      expect(xml).to include('<DonateMark>1</DonateMark>')
      expect(xml).to include('<NPOBAN>25885</NPOBAN>')
    end
  end

  describe 'detail Unit' do
    it 'emits the item unit (Table 2)' do
      items = [Cetustek::Models::InvoiceItem.new(code: 'A', name: 'n', quantity: 1, unit: '本', unit_price: 1)]
      expect(build(items: items)).to include('<Unit>本</Unit>')
    end
  end

  describe 'buyer fields' do
    it 'emits the full Table 1 buyer block' do
      xml = build(buyer_address: '新北市新莊區', buyer_person_in_charge: '楊小胖',
                  buyer_telephone: '0800797899', buyer_facsimile: '02-26511024',
                  buyer_customer_number: 'VIG01')
      expect(xml).to include('<BuyerAddress>新北市新莊區</BuyerAddress>')
      expect(xml).to include('<BuyerPersonInCharge>楊小胖</BuyerPersonInCharge>')
      expect(xml).to include('<BuyerTelephoneNumber>0800797899</BuyerTelephoneNumber>')
      expect(xml).to include('<BuyerFacsimileNumber>02-26511024</BuyerFacsimileNumber>')
      expect(xml).to include('<BuyerCustomerNumber>VIG01</BuyerCustomerNumber>')
    end
  end

  describe 'carrier' do
    it 'mirrors carrier_id into CarrierId2 when only one code is given' do
      xml = build(donate_mark: Cetustek::DonateMark::CARRIER, carrier_type: '3J0002', carrier_id: '/K.1TI+P')
      expect(xml).to include('<CarrierId1>/K.1TI+P</CarrierId1>')
      expect(xml).to include('<CarrierId2>/K.1TI+P</CarrierId2>')
    end

    it 'keeps an explicit CarrierId2' do
      xml = build(donate_mark: Cetustek::DonateMark::CARRIER, carrier_type: 'EJ0011',
                  carrier_id1: 'shown', carrier_id2: 'hidden')
      expect(xml).to include('<CarrierId1>shown</CarrierId1>')
      expect(xml).to include('<CarrierId2>hidden</CarrierId2>')
    end
  end

  describe 'RtnMsg' do
    it 'asks for the JSON return format by default' do
      expect(build).to include('<RtnMsg>Json</RtnMsg>')
    end

    it 'omits RtnMsg when the caller opts out' do
      expect(build(rtn_msg: nil)).not_to include('RtnMsg')
    end
  end

  describe 'optional Table 1 fields' do
    it 'always emits Remark, empty when unset' do
      expect(build).to include('<Remark></Remark>')
      expect(build(remark: '測試')).to include('<Remark>測試</Remark>')
    end

    it 'omits fields that have a platform-side default when unset' do
      xml = build
      expect(xml).not_to include('RoundNum')
      expect(xml).not_to include('MailSend')
      expect(xml).not_to include('ZeroReason')
    end

    it 'emits them when set' do
      xml = build(tax_type: 2, tax_rate: 0, zero_reason: '71', round_num: 0)
      expect(xml).to include('<ZeroReason>71</ZeroReason>')
      expect(xml).to include('<RoundNum>0</RoundNum>')
    end

    it 'emits MailSend, which only applies to carrier invoices' do
      xml = build(donate_mark: Cetustek::DonateMark::CARRIER, buyer_email: 'a@b.c',
                  carrier_type: Cetustek::CarrierType::MOBILE_BARCODE, carrier_id: '/K.1TI+P',
                  mail_send: 1)
      expect(xml).to include('<MailSend>1</MailSend>')
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
