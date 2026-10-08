class EmailIntegrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @gmail_integration = GmailIntegration.recruitment.first
  end

  private

  def require_admin!
    return if current_user.admin?

    redirect_to root_path,
                alert: "You are not authorized to manage email integrations."
  end
end