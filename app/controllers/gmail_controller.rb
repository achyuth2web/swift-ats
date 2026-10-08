class GmailController < ApplicationController
  before_action :authenticate_user!

  def callback
    auth = request.env["omniauth.auth"]
    credentials = auth.credentials

    email = auth.info.email.to_s.downcase

    unless email == ENV.fetch("RECRUITMENT_MAILBOX", "jobs@spritle.com").downcase
      redirect_to email_integrations_path,
                  alert: "Please connect the jobs@spritle.com Google account."
      return
    end

    integration = GmailIntegration.find_or_initialize_by(
      email: email
    )

    integration.assign_attributes(
      access_token: credentials.token,
      token_expires_at: Time.at(credentials.expires_at)
    )

    if credentials.refresh_token.present?
      integration.refresh_token = credentials.refresh_token
    end

    integration.save!

    redirect_to email_integrations_path,
                notice: "Gmail connected successfully."
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error(
      "Gmail connection failed: #{e.message}"
    )

    redirect_to email_integrations_path,
                alert: "Unable to connect Gmail."
  end

  def disconnect
    GmailIntegration
      .where(email: ENV.fetch("RECRUITMENT_MAILBOX", "jobs@spritle.com"))
      .destroy_all

    redirect_to email_integrations_path,
                notice: "Gmail disconnected successfully."
  end
end