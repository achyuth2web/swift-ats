class UsersController < ApplicationController
  before_action :require_admin!
  before_action :set_user, only: [:edit, :update, :destroy, :toggle_active]
  def index
    @users = User.kept.order(:name)
  end
  def new
    @user = User.new(role: "recruiter", active: true)
  end
  def create
    @user = User.new(user_params)
    if @user.save
      log_activity("Admin created user: #{@user.name}")
      redirect_to users_path, notice: "User created."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit; end
  def update
    attrs = user_params
    attrs.delete(:password) if attrs[:password].blank?
    attrs.delete(:password_confirmation) if attrs[:password_confirmation].blank?
    if @user.update(attrs)
      log_activity("Admin updated user: #{@user.name}")
      redirect_to users_path, notice: "User updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    if @user == current_user
      redirect_to users_path, alert: "Cannot delete yourself."
    else
      @user.update_column(
        :email,
        "discarded_#{@user.id}_#{Time.current.to_i}_#{@user.email}"
      )
      @user.discard
      log_activity("Admin deleted user: #{@user.name}")
      redirect_to users_path, notice: "User deleted."
    end
  end
  def toggle_active
    @user.update!(active: !@user.active)
    log_activity("Admin toggled active status for user: #{@user.name}")
    redirect_to users_path, notice: "User #{@user.active? ? 'enabled' : 'disabled'}."
  end
  private
  def set_user = @user = User.find(params[:id])
  def user_params
    params.require(:user).permit(:name,:email,:role,:active,:password,:password_confirmation)
  end
end
