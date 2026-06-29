# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cetustek::PhoneBarcode do
  before do
    Cetustek.configure do |c|
      c.site_id = 'SITE'
      c.username = '53118823'
      c.password = 'PASS'
    end
  end

  def stub_phonebar(phonecode, is_exist)
    stub_request(:get, 'https://api.cetustek.com.tw/PhoneBar.php')
      .with(query: { rentid: '53118823', authkey: 'Cetus9Phone1API7', phonecode: phonecode })
      .to_return(body: %({"isExist":"#{is_exist}","code":"200","msg":"執行成功","version":"1.0"}))
  end

  it 'is valid when the barcode exists (isExist Y)' do
    stub_phonebar('/K.1TI+P', 'Y')
    expect(described_class.valid?('/K.1TI+P')).to be(true)
  end

  it 'is invalid when the barcode does not exist (isExist N)' do
    stub_phonebar('/K.1TB+P', 'N')
    expect(described_class.valid?('/K.1TB+P')).to be(false)
  end

  it 'exposes the full parsed response' do
    stub_phonebar('/K.1TI+P', 'Y')
    expect(described_class.new('/K.1TI+P').response).to include('code' => '200', 'isExist' => 'Y')
  end
end
