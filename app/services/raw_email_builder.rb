class RawEmailBuilder
  def self.call(to:, subject:, body:, from:, in_reply_to: nil, references: nil)
    mail = Mail.new

    mail.from = from
    mail.to = to
    mail.subject = subject
    mail.content_type = "text/plain"
    mail.body = body

    mail["In-Reply-To"] = in_reply_to if in_reply_to.present?
    mail["References"] = references if references.present?

    mail.to_s
  end
end