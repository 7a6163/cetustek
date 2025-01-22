# Cetustek

Cetustek is a Ruby gem designed for handling electronic invoice operations, including invoice cancellation. It communicates with the e-invoice system through SOAP Web Services.

## Features

- Electronic invoice cancellation
- XML format generation
- SOAP Web Services integration

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
Cetustek.configure do |config|
  config.url = 'YOUR_SERVICE_URL'
  config.site_id = 'YOUR_SITE_ID'
  config.username = 'YOUR_USERNAME'
  config.password = 'YOUR_PASSWORD'
end
```

## Usage

### Cancel an Invoice

```ruby
invoice = YourInvoiceModel.find(invoice_id)
cancel_invoice = Cetustek::CancelInvoice.new(invoice)
cancel_invoice.execute
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

## License

This gem is available as open source under the terms of the MIT License.
