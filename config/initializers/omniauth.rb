# config/initializers/omniauth.rb

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV.fetch("GOOGLE_CLIENT_ID"),
    ENV.fetch("GOOGLE_CLIENT_SECRET"),
    scope: "email,profile,https://www.googleapis.com/auth/calendar",
    access_type: "offline",
    prompt: "consent"
end