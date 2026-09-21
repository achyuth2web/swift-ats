class GoogleCalendarSyncService
  RECENT_EVENT_WINDOW = 1.hour

  def initialize(integration)
    @integration = integration
    @service = GoogleCalendarService.new(integration)
  end

  def sync!
    fetch_recent_events.each do |event|
      process_event(event)
    end
  end

  private

  def fetch_recent_events
    events = []
    page_token = nil

    loop do
      response = @service.list_events(
        calendar_id,
        time_min: RECENT_EVENT_WINDOW.ago.iso8601,
        single_events: true,
        order_by: "updated",
        page_token: page_token,
        show_deleted: false
      )

      events.concat(response.items)

      page_token = response.next_page_token
      break if page_token.blank?
    end

    events
  end

  def process_event(event)
    return if event.status == "cancelled"

    properties = event.extended_properties&.private || {}

    # Event was created by ATS already.
    # We don't want to create another Interview.
    return if ats_event?(properties)

    # Only explicitly marked Google events should become ATS interviews.
    return unless ats_created_from_google?(event)

    create_ats_interview(event)
  end

  def create_ats_interview(event)
    # Idempotency protection
    return if Interview.exists?(external_event_id: event.id)

    candidate = candidate_from_event(event)

    return unless candidate

    interviewer_email = interviewer_email_from_event(
      event,
      candidate.email
    )

    return if interviewer_email.blank?

    interview = Interview.create!(
      candidate: candidate,
      scheduled_at: google_event_start_time(event),
      location: event.location,
      interviewer_email: interviewer_email,
      external_event_id: event.id
    )

    link_google_event_to_interview(event, interview)
  end

  def link_google_event_to_interview(event, interview)
    properties = Google::Apis::CalendarV3::Event::ExtendedProperties.new(
      private: {
        "ats_source" => "swift_ats",
        "ats_entity" => "interview",
        "ats_interview_id" => interview.id.to_s
      }
    )

    google_event = Google::Apis::CalendarV3::Event.new(
      extended_properties: properties
    )

    @service.update_event(
      calendar_id,
      event.id,
      google_event,
      send_updates: "none"
    )
  end

  def candidate_from_event(event)
    emails = attendee_emails(event)

    Candidate.find_by(email: emails)
  end

  def interviewer_email_from_event(event, candidate_email)
    attendee_emails(event).find do |email|
      email.casecmp?(candidate_email.to_s) == false
    end
  end

  def attendee_emails(event)
    Array(event.attendees).filter_map do |attendee|
      email = attendee.email.to_s.strip.downcase

      email.presence
    end.uniq
  end

  def google_event_start_time(event)
    if event.start&.date_time.present?
      event.start.date_time
    elsif event.start&.date.present?
      # Handle all-day events if you want to support them.
      Time.zone.parse(event.start.date)
    end
  end

  def ats_event?(properties)
    properties["ats_source"] == "swift_ats" &&
      properties["ats_entity"] == "interview"
  end

  def ats_created_from_google?(event)
    event.summary.to_s.start_with?("[ATS]")
  end

  def calendar_id
    @integration.calendar_id.presence || "primary"
  end
end