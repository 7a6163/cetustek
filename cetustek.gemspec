# frozen_string_literal: true

require_relative "lib/cetustek/version"

Gem::Specification.new do |spec|
  spec.name = "cetustek"
  spec.version = Cetustek::VERSION
  spec.authors = ["Zac"]
  spec.email = ["579103+7a6163@users.noreply.github.com"]

  spec.summary = "A Ruby client for the Cetustek e-invoice API (電子發票加值中心)"
  spec.description = "Cetustek is a Ruby wrapper for the 鯨躍 Cetustek e-invoice API (虛擬多通路, spec AVM-26-03): issuing and cancelling 電子發票 and 折讓單, the read-only queries, and 手機條碼 validation, over SOAP Web Services."
  spec.homepage = "https://github.com/7a6163/cetustek"
  spec.required_ruby_version = ">= 3.3.0"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/7a6163/cetustek"
  spec.metadata["changelog_uri"] = "https://github.com/7a6163/cetustek/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "ox", "~> 2.14"
  spec.add_dependency "savon", "~> 2.14"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
