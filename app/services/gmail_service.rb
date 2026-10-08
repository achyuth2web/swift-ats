require "google/apis/gmail_v1"
require "mail"
require "net/http"
require "uri"
require "json"
require "base64"

class GmailService
  GMAIL_SCOPE = "https://www.googleapis.com/auth/gmail.modify"

  def initialize(integration)
    @integration = integration
    @authorization = GoogleAuthorizationService.new(integration)
    @service = build_gmail_service
  end

  def list_messages(query: nil, max_results: 50)
    response = @service.list_user_messages(
      "me",
      q: query,
      max_results: max_results
    )

    response.messages || []
  end

  def get_message(message_id)
    @service.get_user_message(
      "me",
      message_id,
      format: "full"
    )
  end

  def send_new_email(to:, cc: nil, subject:, body:)
    raw_message = build_new_email(
      to: to,
      cc: cc,
      subject: subject,
      body: body
    )

    send_message(raw_message)
  end

  def send_reply(email_message, body:)
    raw_message = build_reply_email(email_message, body)

    send_message(
      raw_message,
      thread_id: email_message.thread_id
    )
  end

  def send_message(raw_message, thread_id: nil)
    raw_message = raw_message.to_s.gsub(/\r?\n/, "\r\n")
    encoded_raw = Base64.urlsafe_encode64(raw_message)

    payload = { raw: encoded_raw }
    payload[:threadId] = thread_id if thread_id.present?

    authorization = @authorization.authorization

    uri = URI(
      "https://gmail.googleapis.com/gmail/v1/users/me/messages/send"
    )

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] =
      "Bearer #{authorization.access_token}"
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error(
        "Gmail API error #{response.code}: #{response.body}"
      )

      raise "Gmail API request failed with status #{response.code}"
    end

    JSON.parse(response.body)
  end

  private

  def build_gmail_service
    service = Google::Apis::GmailV1::GmailService.new
    service.authorization = @authorization.authorization
    service
  end

  def build_reply_email(email_message, body)
    mail = Mail.new

    mail.from = @integration.email
    mail.to = email_message.from_email
    mail.subject = reply_subject(email_message.subject)
    mail.body = body.to_s

    original_message_id = original_header(
      email_message,
      "Message-ID"
    )

    if original_message_id.present?
      mail.in_reply_to = original_message_id

      existing_references = original_header(
        email_message,
        "References"
      )

      references = [
        existing_references,
        original_message_id
      ].compact_blank.join(" ")

      mail.references = references
    end

    mail.to_s
  end

  def original_header(email_message, name)
    headers = email_message.headers || {}

    headers.find do |key, _value|
      key.to_s.casecmp?(name)
    end&.last
  end

  def reply_subject(subject)
    subject.to_s.match?(/\ARe:/i) ? subject : "Re: #{subject}"
  end

  def build_new_email(to:, cc:, subject:, body:)
    mail = Mail.new

    mail.from = @integration.email
    mail.to = to
    mail.cc = cc if cc.present?
    mail.subject = subject
    mail.body = body.to_s

    mail.to_s
  end
end