class EmailHubMailer < ApplicationMailer
  def custom_email(email_log)
    @email_log = email_log
    @body = email_log.body

    mail(
      to: email_log.recipient_email,
      cc: email_log.cc_email.presence,
      subject: email_log.subject
    )
  end
end
