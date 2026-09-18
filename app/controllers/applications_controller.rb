class ApplicationsController < ApplicationController
  before_action :authenticate!

  def assign
    @application = Application.find(params[:id])
    @recruiter = User.find(params[:assigned_to_id])

    @application.update!(
      assigned_to: @recruiter
    )

    redirect_to @application
  end

  def update
    @application = Application.find(params[:id])

    if @application.update(application_params)
      redirect_to @application
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def application_params
    params.require(:application).permit(
      :status,
      :assigned_to_id
    )
  end
end