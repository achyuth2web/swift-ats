class EmailReplyService
  MAILBOX = ENV.fetch("RECRUITMENT_MAILBOX", "jobs@spritle.com")

  def initialize(application:, user:, body:)
    @application = application
    @user = user
    @body = body
  end

  def call
    latest_email = @application.email_messages
                                .incoming
                                .order(received_at: :desc)
                                .first

    raise "No incoming email found for application" unless latest_email

    subject = reply_subject(latest_email.subject)

    raw_message = RawEmailBuilder.call(
      from: MAILBOX,
      to: latest_email.from_email,
      subject: subject,
      body: @body,
      in_reply_to: latest_email.message_id,
      references: latest_email.message_id
    )

    sent_message =
      GmailService.new(
        access_token: google_access_token
      ).send_message(
        raw_message,
        thread_id: latest_email.thread_id
      )

    @application.email_messages.create!(
      message_id: sent_message.id,
      thread_id: sent_message.thread_id || latest_email.thread_id,
      direction: :outgoing,
      status: :sent,
      from_email: MAILBOX,
      to_emails: latest_email.from_email,
      subject: subject,
      body: @body,
      mailbox: MAILBOX,
      sent_at: Time.current
    )

    sent_message
  end
end