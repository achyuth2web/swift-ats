class EmailProcessor
  MAILBOX = "jobs@spritle.com"

  def initialize(email)
    @email = email
  end

  def call
    email_message = find_or_create_email_message
    application = find_or_create_application(email_message)
    email_message.update!(application: application) if application
    acknowledge_application(application) if application
    application
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

  def find_or_create_application(email_message)
    return if non_recruitment_email?

    Application.find_or_create_by!(
      source: "email",
      source_email: sender_email
    ) do |application|
      application.status = :open
      application.assigned_to = nil
      application.applied_at = @email[:received_at]
    end
  end

  def non_recruitment_email?
    # Keep this simple initially.
    # Later this can use explicit filtering/rules.
    false
  end

  def acknowledge_application(application)
    return unless application

    # Queue acknowledgement email here.
  end
end