class CalendarIntegration < ApplicationRecord
  belongs_to :user

  encrypts :access_token
  encrypts :refresh_token

  enum :provider, {
    google: "google",
    outlook: "outlook"
  }
end