require_relative "boot"
require "rails/all"
Bundler.require(*Rails.groups)

module SwiftAts
  class Application < Rails::Application
    config.load_defaults 7.1
    config.time_zone = "Chennai"
    config.active_record.default_timezone = :local
  end
end
