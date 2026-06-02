class Users::SessionsController < Devise::SessionsController
  layout "devise"
  protect_from_forgery with: :exception, prepend: true

  protected

  def after_sign_in_path_for(resource)
    if resource.admin?
      dashboard_path
    elsif resource.recruiter?
      jobs_path
    else
      destroy_user_session_path
    end
  end
end
