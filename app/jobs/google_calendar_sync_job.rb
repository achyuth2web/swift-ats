class GoogleCalendarSyncJob < ApplicationJob
  queue_as :default

  def perform(calendar_integration_id)
    integration = CalendarIntegration.find(calendar_integration_id)

    GoogleCalendarSyncService.new(integration).sync!
  end
end