class ApplicationsController < ApplicationController
  before_action :authenticate_user!

  def show
    @application = Application
                    .includes(:candidate, :job, :assigned_to)
                    .find(params[:id])

    unless current_user.admin? ||
          @application.assigned_to_id == current_user.id
      redirect_to email_hub_path(tab: "applications"),
                  alert: "You are not authorized to view this application."
      return
    end

    @email_messages = EmailMessage
                        .where(application_id: @application.id)
                        .order(
                          Arel.sql(
                            "COALESCE(received_at, sent_at, created_at) ASC"
                          )
                        )
  end

  def assign
    @application = Application.find(params[:id])
    recruiter_id = params.dig(:application, :assigned_to_id)
    recruiter = User.find(recruiter_id)

    @application.update!(
      assigned_to: recruiter
    )

    redirect_to application_path(@application),
              notice: "Application assigned to #{recruiter.name}."
  end

  def update
    @application = Application.find(params[:id])

    if @application.update(application_params)
      redirect_to @application
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_status
    @application = Application.find(params[:id])

    unless current_user.admin? ||
          @application.assigned_to_id == current_user.id
      redirect_to email_hub_path(tab: "applications"),
                  alert: "You are not authorized to update this application."
      return
    end

    @application.update!(application_status_params)

    redirect_to application_path(@application),
                notice: "Application status updated successfully."
  end

  private

  def application_params
    params.require(:application).permit(
      :status,
      :assigned_to_id
    )
  end

  def application_status_params
    params.require(:application).permit(:status)
  end
end