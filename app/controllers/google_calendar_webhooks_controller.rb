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

    # Process the webhook notification
    # You can enqueue a background job to handle the sync
    # GoogleCalendarSyncJob.perform_later(integration.id)

    GoogleCalendarSyncService.new(integration).sync!

    head :ok
  end
end