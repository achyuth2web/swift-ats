class EmailProcessor
  MAILBOX = ENV.fetch(
    "RECRUITMENT_MAILBOX",
    "jobs@spritle.com"
  )

  def initialize(email)
    @email = email
  end

  def call
    find_or_create_email_message
  end

  private

  def sender_email
    @sender_email ||= begin
      from = @email[:from].to_s
      from[/<([^>]+)>/, 1] || from
    end
  end

  def find_or_create_email_message
    EmailMessage.find_or_create_by!(
      message_id: @email[:message_id]
    ) do |message|
      message.thread_id = @email[:thread_id]
      message.direction = :incoming
      message.status = :received
      message.from_email = sender_email
      message.to_emails = Array(@email[:to]).join(",")
      message.cc_emails = Array(@email[:cc]).join(",")
      message.subject = @email[:subject]
      message.body = @email[:body]
      message.mailbox = MAILBOX
      message.received_at = @email[:received_at]
    end
  end
end