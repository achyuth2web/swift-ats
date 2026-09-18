class SendApplicationAcknowledgementJob < ApplicationJob
  queue_as :default

  MAILBOX = ENV.fetch(
    "RECRUITMENT_MAILBOX",
    "jobs@spritle.com"
  )

  def perform(application_id)
    application = Application.find(application_id)

    recipient = application.source_email
    return if recipient.blank?

    subject = "Application received"

    body = <<~BODY
      Hi,

      Thank you for applying to Spritle.

      We have received your application and our HR team will review it.
      If your profile matches an open opportunity, we will get back to you.

      Regards,
      Spritle HR Team
    BODY

    raw_message = RawEmailBuilder.call(
      from: MAILBOX,
      to: recipient,
      subject: subject,
      body: body
    )

    sent_message = GmailService.new(
      access_token: google_access_token
    ).send_message(raw_message)

    application.email_messages.create!(
      message_id: sent_message.id,
      thread_id: sent_message.thread_id,
      direction: :outgoing,
      status: :sent,
      from_email: MAILBOX,
      to_emails: recipient,
      subject: subject,
      body: body,
      mailbox: MAILBOX,
      sent_at: Time.current
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
      .where(email: MAILBOX)
      .first!
  end
end