# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Cetustek
  # 3.1 手機條碼 API — validates a mobile barcode (手機條碼) against the
  # 財政部 platform. Plain HTTP GET returning JSON, NOT the SOAP service.
  class PhoneBarcode
    ENDPOINT = 'https://api.cetustek.com.tw/PhoneBar.php'
    AUTH_KEY = 'Cetus9Phone1API7' # spec: fixed for now, may become per-account

    def self.valid?(phone_code)
      new(phone_code).valid?
    end

    def initialize(phone_code)
      @phone_code = phone_code
    end

    # true when the barcode exists (isExist == 'Y').
    def valid?
      response['isExist'] == 'Y'
    end

    # Full parsed JSON response: { "isExist", "code", "msg", "TxID", "version" }.
    def response
      uri = URI(ENDPOINT)
      uri.query = URI.encode_www_form(
        rentid: Cetustek.config.username,
        authkey: AUTH_KEY,
        phonecode: @phone_code
      )
      JSON.parse(Net::HTTP.get_response(uri).body)
    end
  end
end
