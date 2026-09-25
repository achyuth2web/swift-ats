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
        show_deleted: true
      )

      events.concat(response.items)

      page_token = response.next_page_token
      break if page_token.blank?
    end

    events
  end

  def process_event(event)
    properties = event.extended_properties&.private || {}

    if event.status == "cancelled"
      handle_cancelled_event(event, properties)
      return
    end

    # Event was created by ATS already.
    # We don't want to create another Interview.
    # return if ats_event?(properties)

    if ats_event?(properties)
      update_existing_interview(event, properties)
      return
    end

    # Only explicitly marked Google events should become ATS interviews.
    return unless ats_created_from_google?(event)

    create_ats_interview(event)
  end

  def create_ats_interview(event)
    # Idempotency protection
    return if Interview.exists?(external_event_id: event.id)

    candidate = candidate_from_event(event)

    return unless candidate

    interviewer_emails = interviewer_emails_from_event(
      event,
      candidate.email
    )

    return if interviewer_emails.blank?

    interview = Interview.create!(
      candidate: candidate,
      round_name: round_name_from_event(event),
      scheduled_at: google_event_start_time(event),
      location: event.location,
      interviewer_email: interviewer_emails,
      calendar_integration_id: @integration.id,
      calendar_provider: calendar_provider,
      calendar_id: calendar_id,
      external_event_id: event.id,
      meeting_url: google_calendar_event_url(event),
      meet_link: google_meet_link(event),
      calendar_sync_status: "synced",
      create_calendar_event: true,
      send_calendar_invitation: event.attendees.present?,
      meeting_type: "online"
    )

    link_google_event_to_interview(event, interview)
  end

  def link_google_event_to_interview(event, interview)
    @service.add_ats_metadata(event.id, interview.id)
  end

  def candidate_from_event(event)
    emails = attendee_emails(event)

    Candidate.find_by(email: emails)
  end

  def interviewer_emails_from_event(event, candidate_email)
    attendee_emails(event)
      .reject { |email| email.casecmp?(candidate_email.to_s) }
      .join(", ")
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
    properties["ats_source"] == "spritle_ats" &&
      properties["ats_entity"] == "interview"
  end

  def ats_created_from_google?(event)
    event.summary.to_s.start_with?("[ATS]")
  end

  def calendar_id
    @integration.calendar_id.presence || "primary"
  end

  def calendar_provider
    @integration.provider || "google"
  end

  def round_name_from_event(event)
    summary = event.summary.to_s

    match = summary.match(
      /\A\[ATS\]\s*Interview\s*-\s*(.+?)\s*-\s*[^-]+\z/i
    )

    match&.captures&.first&.strip
  end

  def update_existing_interview(event, properties)
    interview_id = properties["ats_interview_id"]
    return if interview_id.blank?

    interview = Interview.find_by(id: interview_id)
    return unless interview

    interview.update!(
      scheduled_at: google_event_start_time(event),
      location: event.location,
    )
  end

  def google_calendar_event_url(event)
    Rails.logger.info "Google event html_link: #{event.html_link.inspect}"
    event.html_link.presence
  end

  def google_meet_link(event)
    entry_points = event.conference_data&.entry_points || []

    entry_points
      .find { |entry| entry.entry_point_type == "video" }
      &.uri
  end

  def handle_cancelled_event(event, properties)
    return unless ats_event?(properties)

    interview_id = properties["ats_interview_id"]
    return if interview_id.blank?

    interview = Interview.find_by(id: interview_id)
    return unless interview

    interview.discard unless interview.discarded?
  end
end