class InterviewCalendarService
  Result = Struct.new(:success?, :error, keyword_init: true)

  def initialize(interview, user)
    @interview = interview
    @user = user
  end

  def create_event
    return unless @interview.create_calendar_event?

    event = 
      case @interview.calendar_provider
      when "google"
        create_google_event
      when "outlook"
        create_outlook_event
      else
        raise "Unsupported calendar provider: #{@interview.calendar_provider}"
      end
    
    update_interview(event)

  rescue StandardError => e
    @interview.update(
      calendar_sync_status: "failed"
    )

    Rails.logger.error(
      "Calendar event creation failed for Interview ##{@interview.id}: #{e.message}"
    )
  end

  def update
    case @interview.calendar_provider
    when "google"
      update_google_event
    when "outlook"
      update_outlook_event
    else
      raise "Unsupported calendar provider: #{@interview.calendar_provider}"
    end

    success
  rescue => e
    Rails.logger.error(
      "Interview calendar update failed: #{e.message}"
    )

    failure(e.message)
  end

  def destroy
    return success if @interview.external_event_id.blank?

    case @interview.calendar_provider
    when "google"
      delete_google_event
    when "outlook"
      delete_outlook_event
    else
      raise "Unsupported calendar provider: #{@interview.calendar_provider}"
    end

    success
  rescue => e
    Rails.logger.error(
      "Interview calendar deletion failed: #{e.message}"
    )

    failure(e.message)
  end

  private

  def create_google_event
    integration = @user.google_calendar_integration

    GoogleCalendarService
      .new(integration)
      .create_event(@interview, attendees: attendees)
  end

  def create_outlook_event
    integration = @user.outlook_calendar_integration

    OutlookCalendarService
      .new(integration)
      .create_event(@interview, attendees: attendees)
  end

  def update_google_event
    integration = @user.google_calendar_integration

    GoogleCalendarService
      .new(integration)
      .update_event(@interview, attendees: attendees)
  end

  def delete_google_event
    integration = @user.google_calendar_integration

    GoogleCalendarService
      .new(integration)
      .delete_event(@interview)
  end

  def update_outlook_event
    integration = @user.outlook_calendar_integration

    OutlookCalendarService
      .new(integration)
      .update_event(@interview, attendees: attendees)
  end

  def delete_outlook_event
    integration = @user.outlook_calendar_integration

    OutlookCalendarService
      .new(integration)
      .delete_event(@interview)
  end

  def update_interview(event)
    @interview.update!(
      external_event_id: event.id,
      calendar_id: event.organizer&.email || event.id,
      meeting_url: meeting_url(event),
      calendar_sync_status: "synced"
    )
  end

  def meeting_url(event)
    event.html_link
  end

  def attendees
    @interview.attendees.compact_blank.uniq
  end
  def success
    Result.new(success?: true)
  end
  def failure(message)
    Result.new(
      success?: false,
      error: message
    )
  end
end