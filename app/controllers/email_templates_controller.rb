
class EmailTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_template_management!
  before_action :set_email_template, only: %i[edit update destroy toggle_active]

  def index
    @email_templates = EmailTemplate.order(created_at: :desc)
  end

  def new
    @email_template = EmailTemplate.new(active: true)
  end

  def create
    @email_template = EmailTemplate.new(email_template_params)

    if @email_template.save
      redirect_to email_templates_path,
                  notice: "Email template created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @email_template.update(email_template_params)
      redirect_to email_templates_path,
                  notice: "Email template updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @email_template.destroy!
    redirect_to email_templates_path,
                notice: "Email template deleted successfully."
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to email_templates_path,
                alert: "Unable to delete this email template."
  end

  def toggle_active
    @email_template.update!(active: !@email_template.active?)

    status_message = @email_template.active? ? "activated" : "deactivated"

    redirect_to email_templates_path,
                notice: "Email template #{status_message} successfully."
  rescue ActiveRecord::RecordInvalid
    redirect_to email_templates_path,
                alert: "Unable to update email template status."
  end

  private

  def set_email_template
    @email_template = EmailTemplate.find(params[:id])
  end

  def email_template_params
    params.require(:email_template).permit(
      :name,
      :subject,
      :body
    )
  end

  def authorize_template_management!
    return if current_user.admin? || current_user.hr?

    redirect_to root_path,
                alert: "You are not authorized to manage email templates."
  end
end
