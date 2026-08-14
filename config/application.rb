require_relative "boot"
require "rails/all"
Bundler.require(*Rails.groups)

module SwiftAts
  class Application < Rails::Application
    config.load_defaults 7.1
    config.time_zone = "Chennai"
    config.active_record.default_timezone = :local
    config.active_job.queue_adapter = :async
    config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY")
    config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY")
    config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT")
  end
end
