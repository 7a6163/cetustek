# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::Xml do
  describe '.document' do
    it 'wraps the yielded root in a UTF-8 declaration carrying XSDVersion' do
      xml = described_class.document('Invoice') { |root| root << described_class.tag('OrderId', 'ORD1') }

      expect(xml).to eq(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" \
        "<Invoice XSDVersion=\"2.8\">\n  <OrderId>ORD1</OrderId>\n</Invoice>\n"
      )
      expect(xml.encoding).to eq(Encoding::UTF_8)
    end
  end

  describe '.tag' do
    it 'escapes characters that would otherwise break the document' do
      expect(described_class.tag('Name', '<a & "b">').value)
        .to eq('<Name>&lt;a &amp; &quot;b&quot;&gt;</Name>')
    end

    it 'renders non-string values through to_s' do
      expect(described_class.tag('Qty', 3).value).to eq('<Qty>3</Qty>')
      expect(described_class.tag('Qty', nil).value).to eq('<Qty></Qty>')
    end
  end

  describe '.append' do
    let(:element) { Ox::Element.new('Root') }

    it 'emits an empty tag for a nil value by default' do
      described_class.append(element, 'Remark', nil)
      expect(Ox.dump(element)).to include('<Remark></Remark>')
    end

    it 'leaves the tag out entirely when skip_nil is set, so the platform default applies' do
      described_class.append(element, 'Remark', nil, skip_nil: true)
      expect(Ox.dump(element)).not_to include('Remark')
    end

    it 'still emits the tag when skip_nil is set but the value is present' do
      described_class.append(element, 'Remark', '備註', skip_nil: true)
      # Ox.dump 回 ASCII-8BIT，中文要比對得先跟 document 一樣轉回 UTF-8
      expect(Ox.dump(element).force_encoding('UTF-8')).to include('<Remark>備註</Remark>')
    end
  end

  describe '.parse_response' do
    it 'returns nil for an empty body or the documented nodata sentinel' do
      expect(described_class.parse_response(nil)).to be_nil
      expect(described_class.parse_response('   ')).to be_nil
      expect(described_class.parse_response('nodata')).to be_nil
    end

    it 'raises the documented message for a bare result code' do
      expect { described_class.parse_response('M:InvoiceNumber') }
        .to raise_error(Cetustek::ResultError, /M:.*欄位/)
    end

    it 'returns the root element of a document, ready for parse_fields' do
      root = described_class.parse_response('<?xml version="1.0"?><Invoice><A>1</A></Invoice>')
      expect(root).to be_a(Ox::Element)
      expect(root.value).to eq('Invoice')
    end

    it 'returns a bare element that arrives without a declaration' do
      expect(described_class.parse_response('<Invoice><A>1</A></Invoice>').value).to eq('Invoice')
    end
  end

  describe '.parse_fields' do
    let(:element) { Ox.parse('<Invoice><InvoiceNumber>AB123</InvoiceNumber><NPOBAN></NPOBAN></Invoice>') }

    it 'maps each requested field to a snake_case key' do
      expect(described_class.parse_fields(element, %w[InvoiceNumber NPOBAN Missing]))
        .to eq(invoice_number: 'AB123', npoban: nil, missing: nil)
    end

    it 'returns an empty hash when no fields are asked for' do
      expect(described_class.parse_fields(element, [])).to eq({})
    end
  end

  describe '.text_of' do
    let(:element) { Ox.parse('<Invoice><A>1</A></Invoice>') }

    it 'reads the text of a child element' do
      expect(described_class.text_of(element, 'A')).to eq('1')
    end

    it 'is nil for a missing child or a nil element' do
      expect(described_class.text_of(element, 'B')).to be_nil
      expect(described_class.text_of(nil, 'A')).to be_nil
    end
  end

  describe '.snake_case' do
    it 'splits camelCase into a snake_case symbol' do
      expect(described_class.snake_case('InvoiceNumber')).to eq(:invoice_number)
      expect(described_class.snake_case('NPOBAN')).to eq(:npoban)
      expect(described_class.snake_case('CarrierId2')).to eq(:carrier_id2)
    end
  end
end
