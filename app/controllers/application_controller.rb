class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :check_active!
  protect_from_forgery with: :exception
  helper_method :admin?, :log_activity
  private
  def admin? = current_user&.admin?
  def require_admin!
    redirect_to root_path, alert: "Access denied." unless admin?
  end
  def check_active!
    if current_user && !current_user.active?
      sign_out current_user
      redirect_to new_user_session_path, alert: "Your account has been disabled."
    end
  end
  def log_activity(message)
    ActivityLog.create!(message: message, user: current_user)
  rescue => e
    Rails.logger.warn("Activity log error: #{e.message}")
  end
end
