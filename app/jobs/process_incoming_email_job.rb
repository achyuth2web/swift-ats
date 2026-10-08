class ProcessIncomingEmailJob < ApplicationJob
  queue_as :email

  def perform(message_id)
    return if EmailMessage.exists?(message_id: message_id)

    integration = gmail_integration
    return unless integration

    gmail = GmailService.new(integration)

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

  def gmail_integration
    GmailIntegration.recruitment.first
  end
end