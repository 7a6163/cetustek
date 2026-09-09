# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in cetustek.gemspec
gemspec

group :test do
  gem 'simplecov', require: false
  gem 'simplecov-cobertura', require: false
  gem 'webmock', require: false
end

# mutation testing — mutant needs Ruby >= 3.3, CI still runs 3.0
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3')
  gem 'mutant-rspec', require: false
end
