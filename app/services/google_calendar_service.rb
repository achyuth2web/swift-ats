class GoogleCalendarService
  DEFAULT_INTERVIEW_DURATION = 30.minutes

  def initialize(integration)
    @integration = integration
    @authorization = authorization

    @service = build_calendar_service
    @drive_service = build_drive_service
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
      attendees: build_attendees(attendees),

      conference_data: Google::Apis::CalendarV3::ConferenceData.new(
        create_request:
          Google::Apis::CalendarV3::CreateConferenceRequest.new(
            request_id: SecureRandom.uuid,
            conference_solution_key:
              Google::Apis::CalendarV3::ConferenceSolutionKey.new(
                type: "hangoutsMeet"
              )
          )
      )
    )

    attach_resume(interview, event, attendees)

    created_event = @service.insert_event(
      @integration.calendar_id.presence || "primary",
      event,
      send_updates: interview.send_calendar_invitation? ? "all" : "none",
      supports_attachments: true,
      conference_data_version: 1
    )

    save_meet_link(interview, created_event)

    created_event
  end

  def update_event(interview, attendees: [])
    event = @service.get_event(
      interview.calendar_id,
      interview.external_event_id
    )

    event.summary = "Interview - #{interview.candidate.name}"

    event.start = Google::Apis::CalendarV3::EventDateTime.new(
      date_time: interview.scheduled_at.iso8601
    )

    event.end = Google::Apis::CalendarV3::EventDateTime.new(
      date_time: (
        interview.scheduled_at + DEFAULT_INTERVIEW_DURATION
      ).iso8601
    )

    event.location = interview.location.presence
    event.attendees = build_attendees(attendees)

    update_resume_attachment(
      interview,
      event,
      attendees
    )

    if interview.meet_link.blank? && interview.external_event_id.present?
      event.conference_data =
        Google::Apis::CalendarV3::ConferenceData.new(
          create_request:
            Google::Apis::CalendarV3::CreateConferenceRequest.new(
              request_id: SecureRandom.uuid,
              conference_solution_key:
                Google::Apis::CalendarV3::ConferenceSolutionKey.new(
                  type: "hangoutsMeet"
                )
            )
        )
    end

    updated_event = @service.update_event(
      interview.calendar_id,
      interview.external_event_id,
      event,
      send_updates: interview.send_calendar_invitation? ? "all" : "none",
      supports_attachments: true,
      conference_data_version: 1
    )

    save_meet_link(interview, updated_event)

    updated_event
  end

  def delete_event(interview)
    return if interview.external_event_id.blank?

    @service.delete_event(
      interview.calendar_id,
      interview.external_event_id,
      send_updates: interview.send_calendar_invitation? ? "all" : "none"
    )

    delete_resume_from_drive(interview)
  rescue Google::Apis::ClientError => e
    # Event may already have been deleted manually from Google Calendar.
    raise unless e.status_code == 404

    # Even if the Calendar event is already gone,
    # clean up the Drive resume.
    delete_resume_from_drive(interview)
  end

  private

  # --------------------------------------------------
  # Google authorization
  # --------------------------------------------------

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
    service.authorization = @authorization
    service
  end

  def build_drive_service
    service = Google::Apis::DriveV3::DriveService.new
    service.authorization = @authorization
    service
  end

  # --------------------------------------------------
  # Calendar attendees
  # --------------------------------------------------

  def build_attendees(attendees)
    attendees.map do |email|
      Google::Apis::CalendarV3::EventAttendee.new(
        email: email
      )
    end
  end

  # --------------------------------------------------
  # Resume attachment - CREATE
  # --------------------------------------------------

  def attach_resume(interview, event, attendees)
    candidate = interview.candidate

    return if candidate.resume_file_key.blank?

    drive_file = upload_resume_to_google_drive(candidate)

    return unless drive_file

    grant_drive_permissions(
      drive_file,
      attendees: attendees
    )

    event.attachments = [
      build_calendar_attachment(drive_file)
    ]

    interview.update!(
      resume_drive_file_id: drive_file.id
    )
  rescue StandardError => e
    Rails.logger.error(
      "Failed to attach candidate resume to Google Calendar event " \
      "(interview_id: #{interview.id}, candidate_id: #{candidate.id}): " \
      "#{e.message}"
    )

    nil
  end

  # --------------------------------------------------
  # Resume attachment - UPDATE
  # --------------------------------------------------

  def update_resume_attachment(interview, event, attendees)
    candidate = interview.candidate

    # No resume anymore.
    if candidate.resume_file_key.blank?
      remove_resume_attachment(event)
      delete_resume_from_drive(interview)

      return
    end

    # Candidate has a resume.
    #
    # If we already have a Drive file for this interview,
    # keep using it.
    if interview.resume_drive_file_id.present?
      drive_file = @drive_service.get_file(
        interview.resume_drive_file_id,
        fields: "id,name,mimeType,webViewLink,iconLink"
      )

      grant_drive_permissions(
        drive_file,
        attendees: attendees
      )

      event.attachments = [
        build_calendar_attachment(drive_file)
      ]

      return
    end

    # No Drive file exists yet.
    drive_file = upload_resume_to_google_drive(candidate)

    return unless drive_file

    grant_drive_permissions(
      drive_file,
      attendees: attendees
    )

    event.attachments = [
      build_calendar_attachment(drive_file)
    ]

    interview.update!(
      resume_drive_file_id: drive_file.id
    )
  rescue Google::Apis::ClientError => e
    # Drive file may have been manually deleted.
    if e.status_code == 404
      interview.update!(resume_drive_file_id: nil)

      event.attachments = []

      attach_resume(interview, event, attendees)
    else
      raise
    end
  rescue StandardError => e
    Rails.logger.error(
      "Failed to update resume attachment in Google Calendar " \
      "(interview_id: #{interview.id}, candidate_id: #{candidate.id}): " \
      "#{e.message}"
    )
  end

  def remove_resume_attachment(event)
    event.attachments = []
  end

  # --------------------------------------------------
  # Google Drive upload
  # --------------------------------------------------

  def upload_resume_to_google_drive(candidate)
    resume_url = candidate.resume_url
    return if resume_url.blank?

    uri = URI.parse(resume_url)

    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Failed to download resume from S3: HTTP #{response.code}"
    end

    filename = File.basename(uri.path).presence || "resume"

    file_content = StringIO.new(response.body)

    mime_type = Marcel::MimeType.for(
      file_content,
      name: filename
    )

    file_content.rewind

    file_metadata = Google::Apis::DriveV3::File.new(
      name: filename
    )

    @drive_service.create_file(
      file_metadata,
      upload_source: file_content,
      content_type: mime_type,
      fields: "id,name,mimeType,webViewLink,iconLink"
    )
  end

  # --------------------------------------------------
  # Google Drive permissions
  # --------------------------------------------------

  def grant_drive_permissions(drive_file, attendees:)
    attendees.each do |email|
      next if email.blank?

      permission = Google::Apis::DriveV3::Permission.new(
        type: "user",
        role: "reader",
        email_address: email
      )

      begin
        @drive_service.create_permission(
          drive_file.id,
          permission
        )
      rescue Google::Apis::ClientError => e
        # Permission may already exist.
        raise unless e.status_code == 409
      end
    end
  end

  # --------------------------------------------------
  # Calendar attachment
  # --------------------------------------------------

  def build_calendar_attachment(drive_file)
    Google::Apis::CalendarV3::EventAttachment.new(
      file_url: drive_file.web_view_link,
      title: drive_file.name,
      mime_type: drive_file.mime_type,
      icon_link: drive_file.icon_link
    )
  end

  # --------------------------------------------------
  # Delete Drive resume
  # --------------------------------------------------

  def delete_resume_from_drive(interview)
    return if interview.resume_drive_file_id.blank?

    @drive_service.delete_file(
      interview.resume_drive_file_id
    )

    interview.update!(
      resume_drive_file_id: nil
    )
  rescue Google::Apis::ClientError => e
    # File may already have been deleted manually.
    raise unless e.status_code == 404

    interview.update!(
      resume_drive_file_id: nil
    )
  end

  def save_meet_link(interview, event)
    meet_link = event.conference_data
      &.entry_points
      &.find { |entry| entry.entry_point_type == "video" }
      &.uri

    interview.update!(meet_link: meet_link) if meet_link.present?
  end
end