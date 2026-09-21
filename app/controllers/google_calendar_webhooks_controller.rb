class GoogleCalendarWebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_forgery_protection

  def receive
    channel_id = request.headers["X-Goog-Channel-ID"]
    resource_id = request.headers["X-Goog-Resource-ID"]

    integration = CalendarIntegration.find_by(
      provider: "google",
      google_channel_id: channel_id,
      google_resource_id: resource_id
    )

    return head :not_found unless integration

    GoogleCalendarSyncJob.perform_later(integration.id)

    head :ok
  end
end