class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :check_active!
  before_action :set_cache_headers
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
  def set_cache_headers
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
