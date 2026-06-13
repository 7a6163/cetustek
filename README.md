# Cetustek

[![RSpec Tests](https://github.com/7a6163/cetustek/actions/workflows/rspec.yml/badge.svg)](https://github.com/7a6163/cetustek/actions/workflows/rspec.yml)
[![codecov](https://codecov.io/gh/7a6163/cetustek/graph/badge.svg?token=N951Y9SE15)](https://codecov.io/gh/7a6163/cetustek)

Cetustek is a Ruby gem designed for handling electronic invoice operations, including invoice cancellation. It communicates with the e-invoice system through SOAP Web Services.

## Features

- Electronic invoice cancellation
- XML format generation
- SOAP Web Services integration
- Environment-specific configuration (sandbox/production)
- Service-oriented architecture
- Robust error handling

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
  donate_mark: 0,
  payment_type: 2,
  items: invoice.items.map { |item|
    Cetustek::Models::InvoiceItem.new(
      code: item.sku,
      name: item.name,
      quantity: item.quantity,
      unit_price: item.price
    )
  }
)

result = Cetustek::CreateInvoice.new(invoice_data).execute
# => { number: "GT68514542", random_number: "9654" }
```

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

### Discounts and fees

The gem is a faithful wrapper of the API's invoice detail format, so it has no
built-in discount/coupon/delivery/handling concepts. Model them as ordinary line
items — use a negative `unit_price` for a discount:

```ruby
Cetustek::Models::InvoiceItem.new(code: 'DISCOUNT', name: '折抵', quantity: 1, unit_price: -30)
```

### Cancel an Invoice

```ruby
# `invoice` responds to #number and #created_at; on success (return code "C0")
# it is updated with canceled: true.
Cetustek::CancelInvoice.new(invoice).execute
```

### Query an Invoice by Order ID

```ruby
response = Cetustek::QueryInvoiceByOrderId.query(order_id)
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
