class GoogleCalendarController < ApplicationController
  before_action :authenticate_user!

  def callback
    user = User.find_by(id: current_user.id)

    unless user
      redirect_to calendar_integrations_path,
                  alert: "Unable to connect Google Calendar."
      return
    end

    auth = request.env["omniauth.auth"]

    credentials = auth.credentials

    integration = user.calendar_integrations.find_or_initialize_by(
      provider: "google"
    )

    integration.assign_attributes(
      email: auth.info.email,
      calendar_id: "primary",
      access_token: credentials.token,
      token_expires_at: Time.at(credentials.expires_at)
    )

    # Google may not return a refresh token on every login.
    # Preserve the existing refresh token if it is not returned.
    if credentials.refresh_token.present?
      integration.refresh_token = credentials.refresh_token
    end

    integration.save!

    redirect_to calendar_integrations_path,
                notice: "Google Calendar connected successfully."
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error(
      "Google Calendar connection failed: #{e.message}"
    )

    redirect_to calendar_integrations_path,
                alert: "Unable to connect Google Calendar."
  end

  def failure
    redirect_to calendar_integrations_path,
                alert: "Google Calendar connection failed."
  end

  def disconnect
    current_user.calendar_integrations.google.destroy_all

    redirect_to calendar_integrations_path,
                notice: "Google Calendar disconnected successfully."
  end
end