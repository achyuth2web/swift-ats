class GmailMessageParser
  def initialize(message)
    @message = message
  end

  def parse
    {
      message_id: @message.id,
      thread_id: @message.thread_id,
      from: header("From"),
      to: header("To"),
      cc: header("Cc"),
      subject: header("Subject"),
      body: extract_body(@message.payload),
      received_at: received_at
    }
  end

  private

  def header(name)
    @message.payload.headers.find do |item|
      item.name.casecmp?(name)
    end&.value
  end

  def extract_body(part)
    return decode_body(part.body.data) if text_plain?(part)
    return decode_body(part.body.data) if text_html?(part)

    Array(part.parts).each do |child|
      body = extract_body(child)
      return body if body.present?
    end

    nil
  end

  def text_plain?(part)
    part.mime_type.to_s.casecmp?("text/plain") &&
      part.body&.data.present?
  end

  def text_html?(part)
    part.mime_type.to_s.casecmp?("text/html") &&
      part.body&.data.present?
  end

  def decode_body(data)
    Base64.urlsafe_decode64(data)
  rescue ArgumentError
    data
  end

  def received_at
    timestamp = @message.internal_date

    return Time.current unless timestamp.present?

    Time.at(timestamp.to_i / 1000).utc
  end
end