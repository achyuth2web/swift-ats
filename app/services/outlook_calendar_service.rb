require "net/http"
require "uri"
require "json"

class OutlookCalendarService
  GRAPH_BASE_URL = "https://graph.microsoft.com/v1.0"
  TOKEN_URL = "https://login.microsoftonline.com/#{ENV.fetch('MICROSOFT_TENANT_ID')}/oauth2/v2.0/token"

  def initialize(integration)
    @integration = integration
  end

  def create_event(interview, attendees:)
    response = request(
      :post,
      "/me/events",
      event_payload(interview, attendees)
    )

    parse_response(response)
  end

  def update_event(interview, attendees:)
    response = request(
      :patch,
      "/me/events/#{interview.external_event_id}",
      event_payload(interview)
    )

    parse_response(response)
  end

  def delete_event(interview)
    response = request(
      :delete,
      "/me/events/#{interview.external_event_id}"
    )

    return true if response.code.to_i == 204

    parse_response(response)
  end

  private

  def event_payload(interview, attendees)
    {
      subject: interview.title,

      body: {
        contentType: "HTML",
        content: interview_description(interview)
      },

      start: {
        dateTime: interview.scheduled_at.iso8601
      },

      end: {
        dateTime: interview.scheduled_at.iso8601 + 30.minutes
      },

      attendees: attendees,

      isOnlineMeeting: true,
      onlineMeetingProvider: "teamsForBusiness"
    }
  end

  def interview_description(interview)
    <<~HTML
      <p>Interview scheduled from ATS.</p>
      <p><strong>Interview:</strong> #{interview.round_name}</p>
    HTML
  end

  def request(method, path, payload = nil)
    ensure_valid_access_token!

    uri = URI("#{GRAPH_BASE_URL}#{path}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request_class = case method
                    when :post
                      Net::HTTP::Post
                    when :patch
                      Net::HTTP::Patch
                    when :delete
                      Net::HTTP::Delete
                    end

    request = request_class.new(uri)

    request["Authorization"] = "Bearer #{@integration.access_token}"
    request["Content-Type"] = "application/json"

    request.body = payload.to_json if payload.present?

    response = http.request(request)

    if response.code.to_i == 401
      refresh_access_token!

      request["Authorization"] = "Bearer #{@integration.access_token}"

      response = http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess) || response.code.to_i == 204
      Rails.logger.error(
        "Microsoft Graph error: #{response.code} #{response.body}"
      )

      raise "Microsoft Graph request failed: #{response.code} #{response.body}"
    end

    response
  end

  def parse_response(response)
    return true if response.code.to_i == 204

    JSON.parse(response.body)
  end

  def ensure_valid_access_token!
    return if @integration.token_expires_at.blank?

    # Refresh a little before the actual expiry
    return if @integration.token_expires_at > 5.minutes.from_now

    refresh_access_token!
  end

  def refresh_access_token!
    raise "Outlook refresh token is missing" if @integration.refresh_token.blank?

    uri = URI(TOKEN_URL)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/x-www-form-urlencoded"

    request.set_form_data(
      client_id: ENV.fetch("MICROSOFT_CLIENT_ID"),
      client_secret: ENV.fetch("MICROSOFT_CLIENT_SECRET"),
      refresh_token: @integration.refresh_token,
      grant_type: "refresh_token",
      scope: "openid profile email offline_access User.Read Calendars.ReadWrite"
    )

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error(
        "Microsoft token refresh failed: #{response.code} #{response.body}"
      )

      raise "Unable to refresh Outlook access token"
    end

    data = JSON.parse(response.body)

    @integration.update!(
      access_token: data.fetch("access_token"),
      refresh_token: data["refresh_token"].presence || @integration.refresh_token,
      token_expires_at: Time.current + data.fetch("expires_in").to_i.seconds
    )
  end
end