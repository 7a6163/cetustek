# frozen_string_literal: true

RSpec.describe Cetustek::Soap do
  subject(:caller_object) { Class.new { include Cetustek::Soap }.new }

  around do |example|
    Cetustek.instance_variable_set(:@config, nil)
    example.run
    Cetustek.instance_variable_set(:@config, nil)
  end

  it 'defaults to the HTTPI transport with 300s timeouts' do
    expect(Cetustek.config.transport).to eq(:httpi)
    expect(Savon).to receive(:client)
      .with(wsdl: Cetustek.config.url, open_timeout: 300, read_timeout: 300)
    caller_object.soap_client
  end

  it 'builds a faraday client without the migration-hint options' do
    Cetustek.configure { |c| c.transport = :faraday }

    client = caller_object.soap_client

    expect(client.faraday.options.open_timeout).to eq(300)
    expect(client.faraday.options.read_timeout).to eq(300)
  end

  it 'rejects an unknown transport at configure time' do
    expect { Cetustek.configure { |c| c.transport = :typhoeus } }
      .to raise_error(ArgumentError, /transport must be one of httpi, faraday/)
  end

  describe 'the credentials every operation sends' do
    before do
      Cetustek.configure do |c|
        c.site_id = 'SITE'
        c.password = 'PASS'
        c.username = 'USER'
      end
    end

    it 'builds source from 網站代碼 + APIPassword, in that order' do
      expect(caller_object.source).to eq('SITEPASS')
    end

    it 'sends the 租賃者統編 as rentid' do
      expect(caller_object.rentid).to eq('USER')
    end

    it 'merges source and rentid into every call message' do
      client = instance_double(Savon::Client)
      allow(Savon).to receive(:client).and_return(client)
      allow(client).to receive(:call).and_return(:response)

      expect(caller_object.soap_call(:query_invoice, invoicenumber: 'AB1')).to eq(:response)
      expect(client).to have_received(:call).with(
        :query_invoice, message: { invoicenumber: 'AB1', source: 'SITEPASS', rentid: 'USER' }
      )
    end
  end

  describe '#soap_return' do
    it 'digs the return value out of the operation-named response body' do
      response = double('response', body: { query_invoice_response: { return: 'AB12345678' } })
      expect(caller_object.soap_return(response, :query_invoice)).to eq('AB12345678')
    end
  end
end
