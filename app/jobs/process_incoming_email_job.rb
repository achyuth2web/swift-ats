class ProcessIncomingEmailJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    return if EmailMessage.exists?(message_id: message_id)

    gmail = GmailService.new(
      access_token: google_access_token
    )

    message = gmail.get_message(message_id)

    parsed_email = GmailMessageParser.new(message).parse

    EmailProcessor.new(parsed_email).call
  rescue ActiveRecord::RecordNotUnique
    # Another sync job processed the same Gmail message concurrently.
    Rails.logger.info(
      "Gmail message #{message_id} was already processed"
    )
  end

  private

  def google_access_token
    GoogleTokenService.new(
      integration: google_integration
    ).access_token
  end

  def google_integration
    CalendarIntegration
      .where(provider: "google")
      .where(email: "jobs@spritle.com")
      .first!
  end
end