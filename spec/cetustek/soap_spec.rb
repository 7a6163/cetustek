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
end
