# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::Configuration do
  subject(:config) { described_class.new }

  it 'defaults to the sandbox environment' do
    expect(config.environment).to eq(:sandbox)
    expect(config.sandbox?).to be(true)
    expect(config.production?).to be(false)
  end

  it 'exposes the sandbox WSDL url by default' do
    expect(config.url).to eq('https://invoice.cetustek.com.tw/InvoiceMultiWeb/InvoiceAPI?wsdl')
  end

  context 'when set to production' do
    before { config.environment = :production }

    it 'reports production and exposes the production WSDL url' do
      expect(config.production?).to be(true)
      expect(config.sandbox?).to be(false)
      expect(config.url).to eq('https://www.ei.com.tw/InvoiceMultiWeb/InvoiceAPI?wsdl')
    end
  end

  it 'holds the authentication credentials' do
    config.site_id = 'SITE'
    config.username = 'USER'
    config.password = 'PASS'

    expect([config.site_id, config.username, config.password]).to eq(%w[SITE USER PASS])
  end
end

RSpec.describe Cetustek do
  around do |example|
    original = described_class.instance_variable_get(:@config)
    example.run
    described_class.instance_variable_set(:@config, original)
  end

  it 'memoizes a single global configuration' do
    expect(described_class.config).to be_a(Cetustek::Configuration)
    expect(described_class.config).to equal(described_class.config)
  end

  it 'yields the global configuration to .configure' do
    described_class.configure { |c| c.site_id = 'SITE' }

    expect(described_class.config.site_id).to eq('SITE')
  end
end
