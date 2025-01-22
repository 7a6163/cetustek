# frozen_string_literal: true

require_relative "cetustek/version"

module Cetustek
  class Error < StandardError; end

  def self.configure
    yield config
  end

  def self.config
    @config ||= Config.new
  end
end
