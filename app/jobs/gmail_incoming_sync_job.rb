class GmailIncomingSyncJob < ApplicationJob
  queue_as :email_sync

  MAILBOX = ENV.fetch(
    "RECRUITMENT_MAILBOX",
    "jobs@spritle.com"
  )

  def perform
    integration = gmail_integration
    return unless integration

    gmail = GmailService.new(integration)

    messages = gmail.list_messages(
      query: "to:#{MAILBOX} -from:#{MAILBOX}"
    )

    messages.each do |message|
      ProcessIncomingEmailJob.perform_later(message.id)
    end
  end

  private

  def gmail_integration
    GmailIntegration.recruitment.first
  end
end