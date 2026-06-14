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
