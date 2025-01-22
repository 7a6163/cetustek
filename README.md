# Cetustek

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

### Cancel an Invoice

```ruby
invoice = YourInvoiceModel.find(invoice_id)
invoice_data = Cetustek::Models::InvoiceData.new(
  order_id: invoice.order_id,
  order_date: Time.zone.today,
  buyer_identifier: invoice.receipt,
  buyer_name: invoice.name,
  buyer_email: invoice.email,
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
```

## Development

1. Clone this repository
2. Run `bin/setup` to install dependencies
3. Run `bin/console` for an interactive prompt to experiment

## Requirements

- Ruby >= 2.7.0
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
