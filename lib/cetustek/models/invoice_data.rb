# frozen_string_literal: true

module Cetustek
  # TaxType (稅別) codes accepted by CreateInvoiceV3 (spec V4.16, Table 1).
  module TaxType
    TAXABLE = 1            # 應稅
    ZERO_RATE = 2          # 零稅率(非經海關出口)
    TAX_FREE = 3           # 免稅
    SPECIAL = 4            # 應稅(特種稅率) — requires TaxRate
    ZERO_RATE_CUSTOMS = 5  # 零稅率(經海關出口)
    MIXED = 9              # 混合(應稅、零稅率與免稅，限收銀機類型發票)
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
    class InvoiceData
      DEFAULT_TAX_RATE = 0.05
      DEFAULT_INVOICE_TYPE = '07' # 07: 一般稅額, 08: 特種稅額

      attr_reader :order_id, :order_date, :buyer_identifier, :buyer_name,
                  :buyer_email, :donate_mark, :carrier_type, :carrier_id,
                  :carrier_id2, :npo_ban, :items, :payment_type,
                  :tax_type, :tax_rate, :invoice_type, :hastax

      def initialize(attributes = {})
        @order_id = attributes[:order_id]
        @order_date = attributes[:order_date]
        @buyer_identifier = attributes[:buyer_identifier]
        @buyer_name = attributes[:buyer_name]
        @buyer_email = attributes[:buyer_email]
        @donate_mark = attributes[:donate_mark]
        @carrier_type = attributes[:carrier_type]
        @carrier_id = attributes[:carrier_id]
        @carrier_id2 = attributes[:carrier_id2]
        @npo_ban = attributes[:npo_ban]
        @items = attributes[:items] || []
        @payment_type = attributes[:payment_type]
        @tax_type = attributes[:tax_type] || TaxType::TAXABLE
        @tax_rate = attributes.fetch(:tax_rate, DEFAULT_TAX_RATE)
        @invoice_type = attributes[:invoice_type] || DEFAULT_INVOICE_TYPE
        # hastax: 0 = item prices are tax-exclusive, 1 = tax-inclusive.
        # Comes from the order (e.g. tax-free purchases), not a fixed value.
        @hastax = attributes.fetch(:hastax, 1)
      end

      # 混合稅率發票 (限收銀機)：每筆明細需標註 DType。
      def mixed_tax?
        @tax_type.to_i == TaxType::MIXED
      end
    end

    class InvoiceItem
      # Per-item 稅別註記 (DType) used for mixed-tax invoices (TaxType == 9).
      DTYPE_MAP = {
        taxable: '',    # 應稅商品 -> 空白
        zero_rate: 'TZ', # 零稅率商品
        tax_free: 'TN'   # 免稅商品
      }.freeze

      attr_reader :code, :name, :quantity, :unit_price, :tax_type, :unit

      def initialize(attributes = {})
        @code = attributes[:code]
        @name = attributes[:name]
        @quantity = attributes[:quantity]
        @unit_price = attributes[:unit_price]
        @unit = attributes[:unit]
        @tax_type = attributes[:tax_type] || :taxable
      end

      # Returns the DType code: '', 'TZ' or 'TN'.
      # Accepts the friendly symbols above or a raw code string.
      def d_type
        DTYPE_MAP.fetch(@tax_type) { @tax_type.to_s }
      end
    end
  end
end
