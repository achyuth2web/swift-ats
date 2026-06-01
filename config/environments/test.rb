require "active_support/core_ext/integer/time"
Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.public_file_server.enabled = true
  config.active_storage.service = :test
  config.action_dispatch.show_exceptions = :rescuable
  config.action_controller.raise_on_open_redirects = true
  config.action_view.annotate_rendered_view_with_filenames = true
  config.action_controller.allow_forgery_protection = false
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
end
