class GmailIncomingSyncJob < ApplicationJob
  queue_as :default

  MAILBOX = ENV.fetch(
    "RECRUITMENT_MAILBOX",
    "jobs@spritle.com"
  )

  def perform
    gmail = GmailService.new(
      access_token: google_access_token
    )

    messages = gmail.list_messages(
      query: "to:#{MAILBOX} -from:#{MAILBOX}"
    )

    messages.each do |message|
      ProcessIncomingEmailJob.perform_later(message.id)
    end
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
      .where(email: MAILBOX)
      .first!
  end
end