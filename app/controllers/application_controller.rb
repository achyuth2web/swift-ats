class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :check_active!
  before_action :set_cache_headers
  protect_from_forgery with: :exception
  helper_method :admin?, :log_activity
  private
  def admin? = current_user&.admin?
  def recruiter? = current_user&.recruiter?
  def require_current_user!
    unless current_user
      redirect_to login_path, alert: "Please login first."
    end
  end
  def require_admin!
    redirect_to not_found_path unless admin?
  end

  def require_recruiter!
    redirect_to not_found_path unless recruiter?
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
  def home_path_for(user)
    return new_user_session_path unless user

    if user.admin?
      dashboard_path
    elsif user.recruiter?
      jobs_path
    else
      root_path
    end
  end

  helper_method :home_path_for
end
