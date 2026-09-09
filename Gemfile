# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in cetustek.gemspec
gemspec

group :test do
  gem 'simplecov', require: false
  gem 'simplecov-cobertura', require: false
  gem 'webmock', require: false
end

# mutation testing: bundle exec mutant run
gem 'mutant-rspec', require: false
