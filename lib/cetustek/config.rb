require 'active_support/configurable'

module Cetustek
  class Config
    include ActiveSupport::Configurable

    config_accessor :url
    config_accessor :username
    config_accessor :password
    config_accessor :site_id
  end
end
