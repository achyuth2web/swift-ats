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
    Array(@message.payload.headers).find do |item|
      item.name.casecmp?(name)
    end&.value
  end

  def extract_body(payload)
    parts = collect_text_parts(payload)

    # Prefer plain text; fall back to HTML.
    plain_part = parts.find do |part|
      part.mime_type.to_s.casecmp?("text/plain") &&
        part.body&.data.present?
    end

    html_part = parts.find do |part|
      part.mime_type.to_s.casecmp?("text/html") &&
        part.body&.data.present?
    end

    selected_part = plain_part || html_part
    return nil unless selected_part

    decode_body(selected_part.body.data)
  end

  def collect_text_parts(part, result = [])
    if %w[text/plain text/html].any? do |mime_type|
         part.mime_type.to_s.casecmp?(mime_type)
       end
      result << part
    end

    Array(part.parts).each do |child|
      collect_text_parts(child, result)
    end

    result
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