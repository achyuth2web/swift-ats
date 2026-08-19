class GoogleCalendarService
  DEFAULT_INTERVIEW_DURATION = 30.minutes

  def initialize(integration)
    @integration = integration
    @service = build_calendar_service
  end

  def create_event(interview, attendees:)
    start_time = interview.scheduled_at
    end_time = start_time + DEFAULT_INTERVIEW_DURATION

    event = Google::Apis::CalendarV3::Event.new(
      summary: "Interview - #{interview.candidate.name}",
      description: "Interview scheduled from ATS",
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: start_time.iso8601
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: end_time.iso8601
      ),
      location: interview.location,
      attendees: attendees.map do |email|
        {
          email: email
        }
      end
    )

    @service.insert_event(
      @integration.calendar_id.presence || "primary",
      event,
      send_updates: interview.send_calendar_invitation? ? "all" : "none"
    )
  end

  def update_event(interview, attendees: [])
    event = @service.get_event(
      interview.calendar_id,
      interview.external_event_id
    )

    event.summary = "Interview - #{interview.candidate.name}"
    # event.description = interview_description(interview)

    event.start = Google::Apis::CalendarV3::EventDateTime.new(
      date_time: interview.scheduled_at.iso8601
    )

    event.end = Google::Apis::CalendarV3::EventDateTime.new(
      date_time: (interview.scheduled_at + 30.minutes).iso8601
    )

    event.location = interview.location.presence

    event.attendees = attendees.map do |email|
      Google::Apis::CalendarV3::EventAttendee.new(
        email: email
      )
    end

    @service.update_event(
      interview.calendar_id,
      interview.external_event_id,
      event
    )
  end

  def delete_event(interview)
    return if interview.external_event_id.blank?

    @service.delete_event(
      interview.calendar_id,
      interview.external_event_id
    )
  rescue Google::Apis::ClientError => e
    # Event may already have been deleted manually from Google Calendar.
    raise unless e.status_code == 404
  end

  private

  def authorization
    credentials = Signet::OAuth2::Client.new(
      client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
      client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
      token_credential_uri: "https://oauth2.googleapis.com/token",
      access_token: @integration.access_token,
      refresh_token: @integration.refresh_token,
      expires_at: @integration.token_expires_at&.to_i
    )

    if credentials.expired?
      credentials.fetch_access_token!

      @integration.update!(
        access_token: credentials.access_token,
        token_expires_at: credentials.expires_at
      )
    end

    credentials
  end
  def build_calendar_service
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = authorization
    service
  end
end