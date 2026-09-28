class GoogleCalendarSyncService
  # RECENT_EVENT_WINDOW = 1.hour

  def initialize(integration)
    @integration = integration
    @service = GoogleCalendarService.new(integration)
  end

  def sync!
    events, next_sync_token = fetch_changed_events

    events.each do |event|
      process_event(event)
    end

    @integration.update!(
      sync_token: next_sync_token
    )
  end

  private

  def fetch_changed_events
    events = []
    page_token = nil
    next_sync_token = nil

    loop do
      response =
        if @integration.sync_token.present?
          @service.list_events(
            calendar_id,
            sync_token: @integration.sync_token,
            page_token: page_token,
            show_deleted: true,
            single_events: true
          )
        else
          @service.list_events(
            calendar_id,
            time_min: Time.current.iso8601,
            page_token: page_token,
            show_deleted: true,
            single_events: true
          )
        end

      events.concat(response.items)

      page_token = response.next_page_token

      if response.next_sync_token.present?
        next_sync_token = response.next_sync_token
      end

      break if page_token.blank?
    end

    [events, next_sync_token]
  end

  def process_event(event)
    properties = event.extended_properties&.private || {}

    if event.status == "cancelled"
      handle_cancelled_event(event, properties)
      return
    end

    # Event was created by ATS already.
    # Update the existing ATS Interview instead of creating another one.
    if ats_event?(properties)
      update_existing_interview(event, properties)
      return
    end

    # Only [ATS] Google events should become ATS interviews.
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
      outcome: "Pending",

      calendar_integration_id: @integration.id,
      calendar_provider: calendar_provider,
      calendar_id: calendar_id,
      external_event_id: event.id,

      meeting_url: google_calendar_event_url(event),
      meet_link: google_meet_link(event),

      calendar_sync_status: "synced",
      create_calendar_event: true,
      send_calendar_invitation: event.attendees.present?,
      meeting_type: google_meet_link(event).present? ? "online" : nil
    )

    sync_google_event_with_interview(
      event,
      interview
    )

    interview
  end

  def sync_google_event_with_interview(event, interview)
    google_event = @service.get_event(event.id)

    # Attach candidate resume if available.
    if interview.candidate.resume_file_key.present?
      @service.attach_resume_to_existing_event(
        interview,
        google_event,
        attendees: attendee_emails(event)
      )
    end

    # Add ATS metadata so future Google changes can
    # identify the corresponding ATS Interview.
    google_event.extended_properties ||=
      Google::Apis::CalendarV3::Event::ExtendedProperties.new

    google_event.extended_properties.private ||= {}

    google_event.extended_properties.private.merge!(
      "ats_source" => "spritle_ats",
      "ats_entity" => "interview",
      "ats_interview_id" => interview.id.to_s
    )

    @service.update_existing_event(
      event.id,
      google_event,
      send_updates: "none",
      supports_attachments: true,
      conference_data_version: 1
    )
  end

  def candidate_from_event(event)
    emails = attendee_emails(event)

    Candidate.find_by(email: emails)
  end

  def interviewer_emails_from_event(event, candidate_email)
    attendee_emails(event)
      .reject do |email|
        email.casecmp?(candidate_email.to_s) ||
        email.casecmp?(@integration.email.to_s)
      end
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
      meet_link: google_meet_link(event),
      meeting_url: google_calendar_event_url(event)
    )
  end

  def google_calendar_event_url(event)
    Rails.logger.info(
      "Google event html_link: #{event.html_link.inspect}"
    )

    event.html_link.presence
  end

  def google_meet_link(event)
    entry_points = event.conference_data&.entry_points || []

    entry_points
      .find { |entry| entry.entry_point_type == "video" }
      &.uri
  end

  def handle_cancelled_event(event, _properties)
    interview = Interview.find_by(
      external_event_id: event.id
    )

    return unless interview

    interview.discard unless interview.discarded?
  end
end