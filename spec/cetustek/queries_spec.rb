# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SOAP queries' do
  let(:client) { instance_double(Savon::Client) }
  let(:response) { double('response') }

  before do
    Cetustek.configure do |c|
      c.environment = :sandbox
      c.site_id = 'SITE'
      c.username = 'USER'
      c.password = 'PASS'
    end
    allow(Savon).to receive(:client).and_return(client)
    allow(client).to receive(:call).and_return(response)
  end

  describe Cetustek::QueryInvoice do
    it 'queries by invoice number and year' do
      expect(described_class.query('AB12345678', '2024')).to eq(response)
      expect(client).to have_received(:call).with(
        :query_invoice,
        message: { invoicenumber: 'AB12345678', invoiceyear: '2024', source: 'SITEPASS', rentid: 'USER' }
      )
    end
  end

  describe Cetustek::QueryInvoiceNumberByOrderId do
    it 'queries the invoice number by order id' do
      described_class.query('ORD1')
      expect(client).to have_received(:call).with(
        :query_invoice_number_by_orderid,
        message: { orderid: 'ORD1', source: 'SITEPASS', rentid: 'USER' }
      )
    end
  end

  describe Cetustek::QueryAllowance do
    it 'queries by allowance number' do
      described_class.query('AA1411210027')
      expect(client).to have_received(:call).with(
        :query_allowance,
        message: { allowancenumber: 'AA1411210027', source: 'SITEPASS', rentid: 'USER' }
      )
    end

    describe '.find' do
      let(:xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <Allowance XSDVersion="2.8">
            <AllowanceNumber>AA1411210027</AllowanceNumber>
            <AllowanceDate>2024/02/16</AllowanceDate>
            <InvoiceNumber>AA10000000</InvoiceNumber>
            <InvoiceDate>2024/02/14</InvoiceDate>
            <BuyerIdentifier>12345678</BuyerIdentifier>
            <BuyerName>測試公司</BuyerName>
            <BuyerAddress></BuyerAddress>
            <Reason>退回</Reason>
            <AllowanceStatus>開立</AllowanceStatus>
            <BackStatus>已確認</BackStatus>
            <SaleAmount>95</SaleAmount>
            <TaxAmount>5</TaxAmount>
            <Details>
              <ProductItem>
                <ProductCode>0001</ProductCode>
                <Description>禮券</Description>
                <Quantity>1</Quantity>
                <Unit>本</Unit>
                <UnitPrice>95</UnitPrice>
                <Amount>95</Amount>
                <Tax>5</Tax>
                <TaxType>1</TaxType>
              </ProductItem>
            </Details>
          </Allowance>
        XML
      end

      before { allow(response).to receive(:body).and_return({ query_allowance_response: { return: xml } }) }

      it 'parses the response XML into a hash' do
        result = described_class.find('AA1411210027')

        expect(result[:allowance_number]).to eq('AA1411210027')
        expect(result[:invoice_date]).to eq('2024/02/14')
        expect(result[:buyer_name]).to eq('測試公司')
        expect(result[:buyer_address]).to be_nil
        expect(result[:back_status]).to eq('已確認')
        expect(result[:sale_amount]).to eq('95')
        expect(result[:tax_amount]).to eq('5')
        expect(result[:details]).to eq(
          [{ sequence_number: nil, product_code: '0001', description: '禮券', quantity: '1',
             unit: '本', unit_price: '95', amount: '95', tax: '5', tax_type: '1' }]
        )
      end

      it 'returns nil when the platform answers with nothing' do
        expect(described_class.parse(nil)).to be_nil
        expect(described_class.parse('  ')).to be_nil
      end

      it 'raises with the returned code when the answer is not XML' do
        expect { described_class.parse('M:AllowanceNumber') }
          .to raise_error(Cetustek::ResultError, /M:AllowanceNumber - 欄位未填或格式錯誤/)
      end
    end
  end
end
