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

    describe '.find' do
      let(:xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <Invoice XSDVersion="2.8">
            <OrderID>44556655</OrderID>
            <InvoiceNumber>AA00000027</InvoiceNumber>
            <InvoiceDate>2011/05/19</InvoiceDate>
            <InvoiceTime>19:10:49</InvoiceTime>
            <Seller>
              <Identifier>53118823</Identifier>
              <Name>鯨躍科技有限公司</Name>
              <Address></Address>
              <PersonInCharge></PersonInCharge>
              <TelephoneNumber></TelephoneNumber>
              <FacsimileNumber></FacsimileNumber>
              <EmailAddress>invoice@cetustek.com.tw</EmailAddress>
            </Seller>
            <Buyer>
              <Identifier>55669988</Identifier>
              <Name>漢客料理店</Name>
              <Address></Address>
              <PersonInCharge></PersonInCharge>
              <TelephoneNumber></TelephoneNumber>
              <FacsimileNumber></FacsimileNumber>
              <EmailAddress>hank@cetustek.com.tw</EmailAddress>
            </Buyer>
            <MainRemark></MainRemark>
            <RandomNumber>0958</RandomNumber>
            <InvoiceStatus>開立</InvoiceStatus>
            <DonateMark>0</DonateMark>
            <SalesAmount>120</SalesAmount>
            <TaxAmount>6</TaxAmount>
            <TotalAmount>126</TotalAmount>
            <Details>
              <ProductItem>
                <ProductCode>AA783457</ProductCode>
                <Description>筆記本(綠色)</Description>
                <Quantity>1</Quantity>
                <Unit></Unit>
                <UnitPrice>60</UnitPrice>
                <Amount>60</Amount>
                <SequenceNumber>1</SequenceNumber>
              </ProductItem>
            </Details>
          </Invoice>
        XML
      end

      before { allow(response).to receive(:body).and_return({ query_invoice_response: { return: xml } }) }

      it 'parses the response XML into a hash with seller/buyer/details' do
        result = described_class.find('AA00000027', '2024')

        expect(result[:invoice_number]).to eq('AA00000027')
        expect(result[:invoice_status]).to eq('開立')
        expect(result[:seller]).to include(name: '鯨躍科技有限公司', email_address: 'invoice@cetustek.com.tw')
        expect(result[:buyer]).to include(name: '漢客料理店', identifier: '55669988')
        expect(result[:details]).to eq(
          [{ product_code: 'AA783457', description: '筆記本(綠色)', quantity: '1', unit: nil,
             unit_price: '60', amount: '60', sequence_number: '1' }]
        )
      end

      it 'returns nil for an empty response or the documented "nodata"' do
        expect(described_class.parse(nil)).to be_nil
        expect(described_class.parse('nodata')).to be_nil
      end

      it 'raises with the returned code when the answer is not XML' do
        expect { described_class.parse('M:InvoiceNumber') }
          .to raise_error(Cetustek::ResultError, /M:InvoiceNumber - 欄位未填或格式錯誤/)
      end
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

    describe '.find' do
      it 'returns the bare invoice number' do
        allow(response).to receive(:body)
          .and_return({ query_invoice_number_by_orderid_response: { return: 'AA00000027' } })

        expect(described_class.find('ORD1')).to eq('AA00000027')
      end

      it 'returns nil for the documented "nodata"' do
        allow(response).to receive(:body)
          .and_return({ query_invoice_number_by_orderid_response: { return: 'nodata' } })

        expect(described_class.find('ORD1')).to be_nil
      end

      it 'raises with the returned code when the answer is not a number or "nodata"' do
        allow(response).to receive(:body)
          .and_return({ query_invoice_number_by_orderid_response: { return: 'Invalid' } })

        expect { described_class.find('ORD1') }
          .to raise_error(Cetustek::ResultError, /Invalid - 無效 IP，請通知系統商/)
      end
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

      it 'returns nil for the documented "nodata"' do
        expect(described_class.parse('nodata')).to be_nil
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
