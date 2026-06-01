Rails.application.config.session_store :cookie_store,
  key: "_swift_ats_session",
  same_site: :lax,
  secure: false
