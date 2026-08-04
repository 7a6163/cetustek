# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'
require 'webmock/rspec'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CoberturaFormatter
])

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  minimum_coverage 85
end

require 'cetustek'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configure WebMock
  config.before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  config.after(:each) do
    WebMock.reset!
  end
end

# Helper method to load fixture files
def load_fixture(filename)
  File.read(File.join('spec', 'fixtures', filename))
end

# A minimal set of attributes that satisfies InvoiceData's validations, so each
# example only has to state the fields it actually cares about.
def invoice_attributes(overrides = {})
  {
    order_id: 'ORD1',
    order_date: Date.new(2024, 1, 2),
    donate_mark: Cetustek::DonateMark::PAPER,
    payment_type: Cetustek::PayWay::CASH,
    items: [Cetustek::Models::InvoiceItem.new(code: 'A1', name: 'Item', quantity: 1, unit_price: 100)]
  }.merge(overrides)
end

def invoice_data(overrides = {})
  Cetustek::Models::InvoiceData.new(invoice_attributes(overrides))
end
