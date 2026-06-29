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
