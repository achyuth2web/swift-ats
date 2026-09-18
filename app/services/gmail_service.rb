require "google/apis/gmail_v1"

class GmailService
  GMAIL_SCOPE = "https://www.googleapis.com/auth/gmail.modify"

  def initialize(access_token:)
    @service = Google::Apis::GmailV1::GmailService.new
    @service.authorization = access_token
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

  def send_message(raw_message, thread_id: nil)
    message = Google::Apis::GmailV1::Message.new(
      raw: Base64.urlsafe_encode64(
        raw_message.to_s
      )
    )

    message.thread_id = thread_id if thread_id.present?

    @service.send_user_message(
      "me",
      message
    )
  end
end