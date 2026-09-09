# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'
require 'webmock/rspec'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CoberturaFormatter
])

# mutant 在同一個 process 跑 rspec，跑覆蓋率只是浪費又會蓋掉 coverage/ 產物
unless defined?(Mutant)
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/vendor/'
    minimum_coverage 85
  end
end

require 'cetustek'
require_relative 'support/factories'
require_relative 'support/soap_client'

RSpec.configure do |config|
  config.include Factories

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
