# frozen_string_literal: true

module Cetustek
  # TaxType (稅別) codes accepted by CreateInvoiceV3, spec AVM-26-03 Table 1.
  module TaxType
    TAXABLE = 1            # 應稅
    ZERO_RATE = 2          # 零稅率(非經海關出口)
    TAX_FREE = 3           # 免稅
    SPECIAL = 4            # 應稅(特種稅率) — requires TaxRate
    ZERO_RATE_CUSTOMS = 5  # 零稅率(經海關出口)
    MIXED = 9              # 混合(應稅、零稅率與免稅)
  end

  # CarrierType (載具類別) codes named in spec AVM-26-03 Table 1. The field is
  # 6 chars and 依電子整合平台核發填入, so any other code is accepted as-is.
  module CarrierType
    MOBILE_BARCODE = '3J0002' # 手機條碼，以「/」起始
    CITIZEN_CERT = 'CQ0001'   # 自然人憑證條碼，2 碼大寫字母加 14 碼數字
    CETUSTEK_CARD = 'EJ0011'  # 鯨躍發票卡

    # These carriers 「無顯碼隱碼區分」, so CarrierId1 and CarrierId2 hold the
    # same value. Member carriers (e.g. 鯨躍發票卡) do carry distinct codes.
    WITHOUT_HIDDEN_CODE = [MOBILE_BARCODE, CITIZEN_CERT].freeze
  end

  # PayWay (付款方式) codes for CreateInvoiceV3, spec AVM-26-03 Table 4.
  # Codes are mixed: 1-6 are integers, A-Z are strings. Convenience constants
  # only — InvoiceData#payment_type still accepts any raw value.
  module PayWay
    CASH = 1          # 現金
    ATM = 2           # ATM
    CREDIT_CARD = 3   # 信用卡
    CVS = 4           # 超商代收
    OTHER = 5         # 其他
    E_PAYMENT = 6     # 電子支付
    APPLE_PAY = 'A'   # Apple Pay
    AFTEE = 'E'       # 先享後付 Aftee
    GOOGLE_PAY = 'G'  # Google Pay
    JKO_PAY = 'J'     # 街口支付
    LINE_PAY = 'L'    # Line Pay
    PI_WALLET = 'P'   # Pi 拍錢包、慢點付
    SAMSUNG_PAY = 'S' # Samsung Pay
    TAIWAN_PAY = 'T'  # 台灣 Pay
    EASY_WALLET = 'U' # 悠遊付
    PX_PAY = 'W'      # 全盈+PAY
    QUAN_PAY = 'X'    # 全支付
    COIN_CARD = 'Z'   # 銀角零卡
  end

  # DonateMark (捐贈註記) codes for CreateInvoiceV3, spec AVM-26-03 Table 1.
  # Convenience constants only — InvoiceData#donate_mark still accepts any raw value.
  module DonateMark
    CARRIER = 0 # 載具
    DONATE = 1  # 捐贈
    PAPER = 2   # 紙本
  end

  module Models
    # Request data for CreateInvoiceV3 (開立發票), spec AVM-26-03 Table 1/2.
    # Rules the spec fixes in print are enforced here; anything needing an
    # external lookup (捐贈碼、手機條碼是否存在) is left to the caller.
    class InvoiceData
      DEFAULT_TAX_RATE = 0.05
      DEFAULT_INVOICE_TYPE = '07'  # 一般稅額電子發票
      SPECIAL_INVOICE_TYPE = '08'  # 特種稅額電子發票
      # Json 回傳才拿得到平台配發的發票日期時間；Intertemporal 回開會讓本機日期失準。
      DEFAULT_RTN_MSG = 'Json'
      MAX_ITEMS = 9999
      MAX_REMARK_LENGTH = 200
      ROUND_NUMS = (0..7).freeze
      TAX_TYPES = [TaxType::TAXABLE, TaxType::ZERO_RATE, TaxType::TAX_FREE,
                   TaxType::SPECIAL, TaxType::ZERO_RATE_CUSTOMS, TaxType::MIXED].freeze
      ZERO_RATE_TAX_TYPES = [TaxType::ZERO_RATE, TaxType::ZERO_RATE_CUSTOMS].freeze
      DONATE_MARKS = [DonateMark::CARRIER, DonateMark::DONATE, DonateMark::PAPER].freeze

      attr_reader :order_id, :order_date, :buyer_identifier, :buyer_name,
                  :buyer_email, :buyer_address, :buyer_person_in_charge,
                  :buyer_telephone, :buyer_facsimile, :buyer_customer_number,
                  :donate_mark, :carrier_type, :carrier_id1, :carrier_id2,
                  :npo_ban, :items, :payment_type, :tax_type, :tax_rate,
                  :zero_reason, :invoice_type, :hastax, :remark, :round_num,
                  :mail_send, :rtn_msg

      alias carrier_id carrier_id1

      def initialize(attributes = {})
        @order_id = attributes[:order_id]
        @order_date = attributes[:order_date]
        @buyer_identifier = attributes[:buyer_identifier]
        @buyer_name = attributes[:buyer_name]
        @buyer_email = attributes[:buyer_email]
        @buyer_address = attributes[:buyer_address]
        @buyer_person_in_charge = attributes[:buyer_person_in_charge]
        @buyer_telephone = attributes[:buyer_telephone]
        @buyer_facsimile = attributes[:buyer_facsimile]
        @buyer_customer_number = attributes[:buyer_customer_number]
        @donate_mark = attributes[:donate_mark]
        @carrier_type = attributes[:carrier_type]
        @carrier_id1 = attributes[:carrier_id1] || attributes[:carrier_id]
        @carrier_id2 = attributes[:carrier_id2] || mirrored_carrier_id2
        @npo_ban = attributes[:npo_ban]
        @items = attributes[:items] || []
        @payment_type = attributes[:payment_type]
        @tax_type = attributes[:tax_type] || TaxType::TAXABLE
        # 特種稅率是營業性質決定的，不能沿用 5% 預設值。
        @tax_rate = attributes.fetch(:tax_rate) { special_tax? ? nil : DEFAULT_TAX_RATE }
        @zero_reason = attributes[:zero_reason]
        @invoice_type = attributes[:invoice_type] || DEFAULT_INVOICE_TYPE
        # hastax: 0 = item prices are tax-exclusive, 1 = tax-inclusive.
        # Comes from the order (e.g. tax-free purchases), not a fixed value.
        @hastax = attributes.fetch(:hastax, 1)
        @remark = attributes[:remark]
        @round_num = attributes[:round_num]
        @mail_send = attributes[:mail_send]
        @rtn_msg = attributes.fetch(:rtn_msg, DEFAULT_RTN_MSG)
        validate!
      end

      # 混合稅率發票：每筆明細需標註 DType。
      def mixed_tax?
        @tax_type.to_i == TaxType::MIXED
      end

      # 特種稅額發票：TaxRate 必填，InvoiceType 必須為 08。
      def special_tax?
        @tax_type.to_i == TaxType::SPECIAL
      end

      private

      # 只有無顯碼隱碼區分的載具能自動補 CarrierId2；會員載具兩碼不同，猜了就是送錯。
      def mirrored_carrier_id2
        @carrier_id1 if CarrierType::WITHOUT_HIDDEN_CODE.include?(@carrier_type.to_s)
      end

      def validate!
        raise ArgumentError, 'order_id is required' if blank?(@order_id)

        validate_order_date!
        validate_items!
        validate_donate_mark!
        validate_pay_way!
        validate_tax!
        validate_remark!
        validate_round_num!
      end

      def validate_order_date!
        raise ArgumentError, 'order_date is required' if @order_date.nil?
        return if @order_date.respond_to?(:strftime)

        raise ArgumentError, "order_date must be a Date or Time, got #{@order_date.class}"
      end

      def validate_items!
        raise ArgumentError, 'items must not be empty (沒有產品明細)' if @items.empty?
        raise ArgumentError, "items must not exceed #{MAX_ITEMS} lines" if @items.size > MAX_ITEMS
      end

      def validate_donate_mark!
        raise ArgumentError, 'donate_mark is required (0 載具, 1 捐贈, 2 紙本)' if blank?(@donate_mark)

        unless code_in?(DONATE_MARKS, @donate_mark)
          raise ArgumentError, "donate_mark must be 0 (載具), 1 (捐贈) or 2 (紙本), got #{@donate_mark.inspect}"
        end

        case @donate_mark.to_i
        when DonateMark::CARRIER then validate_carrier!
        when DonateMark::DONATE then validate_npo_ban!
        end

        return if @mail_send.nil? || @donate_mark.to_i == DonateMark::CARRIER

        raise ArgumentError, 'mail_send may only be used when donate_mark is 0 (載具)'
      end

      # CarrierType is left out of the required set on purpose: 鯨躍發票卡
      # 「載具類別可為空或填 EJ0011」, and a blank value is how the platform is
      # told to use it.
      def validate_carrier!
        missing = { buyer_email: @buyer_email, carrier_id1: @carrier_id1,
                    carrier_id2: @carrier_id2 }.select { |_name, value| blank?(value) }.keys
        return if missing.empty?

        raise ArgumentError, "#{missing.join(', ')} required when donate_mark is 0 (載具)" \
                             "#{'; 此載具有顯碼與隱碼之分，請分別填入' if missing == [:carrier_id2]}"
      end

      def validate_npo_ban!
        return if @npo_ban.to_s.match?(/\A\d{3,7}\z/)

        raise ArgumentError, "npo_ban must be a 3-7 digit 捐贈碼 when donate_mark is 1 (捐贈), got #{@npo_ban.inspect}"
      end

      def validate_pay_way!
        raise ArgumentError, 'payment_type is required (see Cetustek::PayWay)' if blank?(@payment_type)
      end

      def validate_tax!
        unless code_in?(TAX_TYPES, @tax_type)
          raise ArgumentError, "tax_type must be one of #{TAX_TYPES.join(', ')}, got #{@tax_type.inspect}"
        end

        validate_zero_reason!
        return unless special_tax?

        raise ArgumentError, 'tax_rate is required when tax_type is 4 (特種稅率)' if blank?(@tax_rate)
        return if @invoice_type.to_s == SPECIAL_INVOICE_TYPE

        raise ArgumentError, "invoice_type must be '08' (特種稅額) when tax_type is 4, got #{@invoice_type.inspect}"
      end

      def validate_zero_reason!
        return if @zero_reason.nil? || ZERO_RATE_TAX_TYPES.include?(@tax_type.to_i)

        raise ArgumentError, 'zero_reason may only be used when tax_type is 2 or 5 (零稅率)'
      end

      def validate_remark!
        return if @remark.to_s.length <= MAX_REMARK_LENGTH

        raise ArgumentError, "remark must not exceed #{MAX_REMARK_LENGTH} characters"
      end

      def validate_round_num!
        return if @round_num.nil? || code_in?(ROUND_NUMS, @round_num)

        raise ArgumentError, "round_num must be between #{ROUND_NUMS.first} and #{ROUND_NUMS.last}, " \
                             "got #{@round_num.inspect}"
      end

      # 'x'.to_i 是 0，而 0 是「載具」「四捨五入」的有效代碼 —— 用 to_i 比對，
      # 亂填的值會被當成 0 靜靜送出去。代碼一律轉字串比對。
      def code_in?(codes, value)
        codes.map(&:to_s).include?(value.to_s)
      end

      def blank?(value)
        value.to_s.strip.empty?
      end
    end

    # A single 明細 row, spec AVM-26-03 Table 2 (發票) / Table 16 (折讓).
    # 品名代號、品名、數量、單價 are 必填; 單位 is not.
    class InvoiceItem
      # Per-item 稅別註記 (DType) used for mixed-tax invoices (TaxType == 9).
      DTYPE_MAP = {
        taxable: '',    # 應稅商品 -> 空白
        zero_rate: 'TZ', # 零稅率商品
        tax_free: 'TN'   # 免稅商品
      }.freeze
      REQUIRED = %i[code name quantity unit_price].freeze

      attr_reader :code, :name, :quantity, :unit_price, :tax_type, :unit

      def initialize(attributes = {})
        @code = attributes[:code]
        @name = attributes[:name]
        @quantity = attributes[:quantity]
        @unit_price = attributes[:unit_price]
        @unit = attributes[:unit]
        @tax_type = attributes[:tax_type] || :taxable
        validate!
      end

      # Returns the DType code: '', 'TZ' or 'TN'.
      # Accepts the friendly symbols above or a raw code string.
      def d_type
        DTYPE_MAP.fetch(@tax_type) { @tax_type.to_s }
      end

      private

      def validate!
        missing = REQUIRED.select { |name| blank?(public_send(name)) }
        return if missing.empty?

        raise ArgumentError, "item #{missing.join(', ')} required (品名代號、品名、數量、單價皆必填)"
      end

      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end
    end
  end
end
