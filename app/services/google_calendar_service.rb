class GoogleCalendarService
  def initialize(integration)
    @integration = integration
  end

  def create_event(interview)
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = authorization

    event = Google::Apis::CalendarV3::Event.new(
      summary: "Interview - #{interview.candidate.name}",
      description: "Interview scheduled from ATS",
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: interview.start_time.iso8601
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: interview.end_time.iso8601
      ),
      attendees: [
        {
          email: interview.candidate.email
        },
        {
          email: interview.interviewer.email
        }
      ]
    )

    service.insert_event(
      "primary",
      event,
      send_updates: "all"
    )
  end
end