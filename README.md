# Cetustek

[![Gem Version](https://img.shields.io/gem/v/cetustek)](https://rubygems.org/gems/cetustek)
[![RSpec Tests](https://github.com/7a6163/cetustek/actions/workflows/rspec.yml/badge.svg)](https://github.com/7a6163/cetustek/actions/workflows/rspec.yml)
[![codecov](https://codecov.io/gh/7a6163/cetustek/graph/badge.svg?token=N951Y9SE15)](https://codecov.io/gh/7a6163/cetustek)

Cetustek is a Ruby wrapper for the 鯨躍 Cetustek e-invoice API (虛擬多通路,
spec AVM-26-03), covering 電子發票 and 折讓單 over SOAP Web Services.

## Features

- 開立發票 (CreateInvoiceV3) with 載具/捐贈/紙本, 零稅率, 混合稅率 and 特種稅額 support
- 作廢發票 (CancelInvoice), including the 專案作廢核准文號 for late cancellations
- 折讓單: 開立 (CreateAllowance), 作廢 (CancelAllowance), 查詢 (QueryAllowance)
- Queries by invoice number or order id, plus 手機條碼 validation
- Validation of the rules the spec fixes in print, before anything is sent
- Result codes raised as `Cetustek::ResultError` with the documented reason
- Environment-specific configuration (sandbox/production) and opt-in logging

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cetustek'
```

Then execute:

```bash
bundle install
```

## Configuration

Configure Cetustek in your application:

```ruby
# config/initializers/cetustek.rb
Cetustek.configure do |config|
  # Set environment (:production or :sandbox)
  config.environment = Rails.env.production? ? :production : :sandbox
  
  # Set authentication credentials
  config.site_id = ENV['CETUSTEK_SITE_ID']
  config.username = ENV['CETUSTEK_USERNAME']
  config.password = ENV['CETUSTEK_PASSWORD']

  # Optional. Defaults to nil, i.e. this gem writes nothing anywhere.
  # Only the order id, invoice number and result code are logged (never the
  # response body); the request XML is logged at debug level on failure.
  config.logger = Rails.logger
end
```

## Usage

### Issue an Invoice

```ruby
invoice = YourInvoiceModel.find(invoice_id)
invoice_data = Cetustek::Models::InvoiceData.new(
  order_id: invoice.order_id,
  order_date: Time.zone.today,
  buyer_identifier: invoice.receipt,
  buyer_name: invoice.name,
  buyer_email: invoice.email,
  donate_mark: Cetustek::DonateMark::CARRIER,
  carrier_type: '3J0002',        # 手機條碼
  carrier_id: invoice.barcode,   # CarrierId2 is mirrored automatically
  payment_type: Cetustek::PayWay::ATM,
  items: invoice.items.map { |item|
    Cetustek::Models::InvoiceItem.new(
      code: item.sku,
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      unit_price: item.price
    )
  }
)

result = Cetustek::CreateInvoice.new(invoice_data).execute
# => { number: "WB02100001", random_number: "3690",
#      date: "2026/02/10", time: "11:19:57",
#      sale_amount: 666, zero_amount: 0, free_amount: 0,
#      tax_amount: 0, total_amount: 666, carrier_url: "..." }
```

Always use the returned `:date`/`:time` as the invoice date. The platform's
`Intertemporal` default issues invoices dated in the previous filing period on
the 1st–2nd of a month, so the local date can be wrong.
Persisting the result is the caller's job — this gem writes to no database.

`InvoiceData.new` raises `ArgumentError` for the rules the spec fixes in print,
so a guaranteed rejection never leaves your process:

- `order_id`, `order_date` (a `Date`/`Time`), `items`, `donate_mark` and `payment_type` are required
- `donate_mark: 0` (載具) requires `buyer_email`, `carrier_type` and `carrier_id`
- `donate_mark: 1` (捐贈) requires a 3–7 digit `npo_ban`
- `tax_type: 4` (特種稅率) requires an explicit `tax_rate` and `invoice_type: '08'`

Anything needing an external lookup (是否為有效手機條碼、捐贈碼是否存在) is left
to the caller — see `Cetustek::PhoneBarcode` below.

Any result code other than a successful issue raises `Cetustek::ResultError`,
whose `#code` is the raw Table 7 code and whose message carries the documented
reason (`S7 - 訂單號碼已存在，若需重開請先作廢原發票號碼`, `D3_2 - 單價未填或格式錯誤`, …).

### Tax types (稅別)

`InvoiceData` defaults to taxable (`TaxType` 1) with a tax rate of `0.05` and a
general invoice type of `07`. Use `Cetustek::TaxType` to switch modes:

| Constant | Code | Meaning |
|----------|------|---------|
| `TAXABLE`           | 1 | 應稅 |
| `ZERO_RATE`         | 2 | 零稅率(非經海關出口) |
| `TAX_FREE`          | 3 | 免稅 |
| `SPECIAL`           | 4 | 應稅(特種稅率) — set `tax_rate`, use `invoice_type: '08'` |
| `ZERO_RATE_CUSTOMS` | 5 | 零稅率(經海關出口) |
| `MIXED`             | 9 | 混合(應稅/零稅率/免稅，限收銀機類型發票) |

#### Zero-rate invoice (零稅率)

```ruby
Cetustek::Models::InvoiceData.new(
  # ...buyer fields, items...
  tax_type: Cetustek::TaxType::ZERO_RATE,
  tax_rate: 0
)
```

#### Mixed-tax invoice (混稅, cash-register invoices only)

For `TaxType` 9 each line item must declare its own tax category via `tax_type`.
Accepts the symbols `:taxable` (default), `:zero_rate`, `:tax_free`, or the raw
`DType` codes (`''`, `'TZ'`, `'TN'`):

```ruby
Cetustek::Models::InvoiceData.new(
  # ...buyer fields...
  tax_type: Cetustek::TaxType::MIXED,
  items: [
    Cetustek::Models::InvoiceItem.new(code: 'A', name: '應稅品',  quantity: 1, unit_price: 100),
    Cetustek::Models::InvoiceItem.new(code: 'B', name: '零稅率品', quantity: 1, unit_price: 100, tax_type: :zero_rate),
    Cetustek::Models::InvoiceItem.new(code: 'C', name: '免稅品',  quantity: 1, unit_price: 100, tax_type: :tax_free)
  ]
)
```

### Payment method (`payment_type` / PayWay)

`payment_type` accepts any raw code, or use `Cetustek::PayWay` for readability
(`payment_type: Cetustek::PayWay::LINE_PAY`):

| Constant | Code | | Constant | Code |
|----------|------|-|----------|------|
| `CASH` | 1 | | `GOOGLE_PAY` | `G` |
| `ATM` | 2 | | `JKO_PAY` | `J` |
| `CREDIT_CARD` | 3 | | `LINE_PAY` | `L` |
| `CVS` | 4 | | `PI_WALLET` | `P` |
| `OTHER` | 5 | | `SAMSUNG_PAY` | `S` |
| `E_PAYMENT` | 6 | | `TAIWAN_PAY` | `T` |
| `APPLE_PAY` | `A` | | `EASY_WALLET` | `U` |
| `AFTEE` | `E` | | `PX_PAY` | `W` |
| | | | `QUAN_PAY` | `X` |
| | | | `COIN_CARD` | `Z` |

### Donation mark (`donate_mark` / DonateMark)

`donate_mark` accepts any raw code, or use `Cetustek::DonateMark`:
`CARRIER` (0, 載具), `DONATE` (1, 捐贈), `PAPER` (2, 紙本).

### Discounts and fees

The gem is a faithful wrapper of the API's invoice detail format, so it has no
built-in discount/coupon/delivery/handling concepts. Model them as ordinary line
items — use a negative `unit_price` for a discount:

```ruby
Cetustek::Models::InvoiceItem.new(code: 'DISCOUNT', name: '折抵', quantity: 1, unit_price: -30)
```

### Cancel an Invoice (作廢發票確認)

```ruby
Cetustek::CancelInvoice.new('AB12345678', 2024).execute                    # => "C0"
Cetustek::CancelInvoice.new('AB12345678', 2024, remark: '明細錯誤').execute # 作廢原因，預設 '退貨'

# 超過申報期間才需要專案作廢核准文號 (否則會收到 C3)
Cetustek::CancelInvoice.new('AB12345678', 2024, return_tax_document_number: '65327645').execute
```

Uploading is not the end of it: the cancellation still has to be confirmed
manually on the 鯨躍 platform before the invoice counts as void. Any code other
than `"C0"` raises `Cetustek::ResultError` (`C5 - 該發票已經作廢過`, …), and
marking your own record as canceled is the caller's job.

### Query invoices

```ruby
Cetustek::QueryInvoiceByOrderId.query(order_id)             # by order id
Cetustek::QueryInvoice.query(invoice_number, invoice_year)  # by invoice number + year
Cetustek::QueryInvoiceNumberByOrderId.query(order_id)       # just the invoice number
```

### Tax-inclusive vs tax-exclusive prices (`hastax`)

`hastax` comes from the order, not a fixed value: `1` (default) means the item
`unit_price`s already include tax; `0` means they are tax-exclusive (e.g. a tax-free
purchase). Set it on `InvoiceData`:

```ruby
Cetustek::Models::InvoiceData.new(hastax: 0, items: [...])
```

### Other Table 1 fields

| Attribute | Tag | Notes |
|-----------|-----|-------|
| `buyer_address` / `buyer_person_in_charge` / `buyer_telephone` / `buyer_facsimile` / `buyer_customer_number` | `BuyerAddress` / `BuyerPersonInCharge` / `BuyerTelephoneNumber` / `BuyerFacsimileNumber` / `BuyerCustomerNumber` | 選填，常用於 B2B |
| `remark` | `Remark` | 備註，200 字 |
| `zero_reason` | `ZeroReason` | 零稅率原因;未填時平台預設 `72`(TaxType 2)或 `71`(TaxType 5) |
| `round_num` | `RoundNum` | 金額計算位數,未填預設 4 |
| `mail_send` | `MailSend` | `0`(預設)由加值中心寄送通知,`1` 自行處理 |
| `rtn_msg` | `RtnMsg` | 預設 `'Json'`;傳 `nil` 退回只回傳 15 碼字串的舊模式 |

Fields with a platform-side default (`ZeroReason`, `RoundNum`, `MailSend`,
`RtnMsg`) are omitted from the XML entirely when `nil`, so the platform applies
its own default. `Intertemporal`(發票回開)is deliberately not exposed: it changes
which filing period's 字軌 the invoice is issued under, and the platform default
is the right behaviour.

### Allowances (折讓單)

```ruby
allowance = Cetustek::Models::AllowanceData.new(
  allowance_number: 'AA20240216000001',
  allowance_date: Time.zone.today,
  invoice_number: 'AA10000000',
  invoice_year: '2024',
  tax_type: 1,
  reason: '退回',
  items: [
    Cetustek::Models::InvoiceItem.new(code: '0001', name: '禮券', quantity: 1, unit: '本', unit_price: 800)
  ]
)
Cetustek::CreateAllowance.new(allowance).execute              # => "A0" on success
Cetustek::CancelAllowance.new('AA20240216000001', '明細錯誤').execute # => "C0" on success
Cetustek::QueryAllowance.find('AA20240216000001')             # parsed Hash, nil if unknown
Cetustek::QueryAllowance.query('AA20240216000001')            # raw Savon response
```

`tax_type` on an allowance only accepts `1` 應稅, `2` 零稅率 or `3` 免稅 — the
invoice-only values (`4`, `5`, `9`) raise `ArgumentError`. `unit_price` is
**tax-inclusive** (there is no `hastax` on allowances).

Any other result code raises `Cetustek::ResultError`, whose `#code` is the raw
code and whose message includes the documented reason (e.g. `A2 - 所有折讓金額加總
不能大於原發票金額`, `C2 - 折讓單已申報，無法作廢`).

`QueryAllowance.find` returns the Table 20 fields as snake_case symbols with the
line items under `:details`, values kept as the raw strings from the XML:

```ruby
{ allowance_number: 'AA20240216000001', allowance_date: '2024/02/16',
  invoice_number: 'AA10000000', invoice_date: '2024/02/14',
  buyer_identifier: '12345678', buyer_name: '測試公司', buyer_address: nil,
  reason: '退回', allowance_status: '開立', back_status: '已確認',
  sale_amount: '95', tax_amount: '5',
  details: [{ sequence_number: '1', product_code: '0001', description: '禮券',
              quantity: '1', unit: '本', unit_price: '95', amount: '95',
              tax: '5', tax_type: '1' }] }
```

### Mobile barcode validation (手機條碼)

```ruby
Cetustek::PhoneBarcode.valid?('/ABC123')  # => true / false
```

## Development

1. Clone this repository
2. Run `bin/setup` to install dependencies
3. Run `bin/console` for an interactive prompt to experiment
4. Run `bundle exec rspec` to run the test suite

## Requirements

- Ruby >= 3.0.0
- `ox` gem for XML processing
- `savon` gem for SOAP services

## Contributing

1. Fork this project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Versioning

This project follows [Semantic Versioning](https://semver.org/). See the [CHANGELOG.md](CHANGELOG.md) file for version details.

## License

This gem is available as open source under the terms of the MIT License.
