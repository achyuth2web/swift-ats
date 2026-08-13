class JobsController < ApplicationController
  before_action :set_job, only: [:show, :edit, :update, :destroy, :update_status]
  def index
    @jobs = current_user.visible_jobs.order(created_at: :desc).includes(:recruiters, :candidates)
    @jobs = @jobs.where(status: params[:status]) if params[:status].present?
    @jobs = @jobs.where("title ILIKE ?", "%#{params[:q]}%") if params[:q].present?
    @jobs = @jobs.page(params[:page]).per(6)
  end
  def show
    @candidates = @job.candidates.kept.order(created_at: :desc)
  end
  def new
    @job = Job.new(status: "Open", open_date: Date.today)
    @job.job_openings.build(sequence_no: 1)
    @recruiters = User.kept.where(role: "recruiter", active: true)
  end
  def create
    @job = Job.new(job_params)
    @job.open_date ||= Date.today
    if @job.save
      update_recruiters
      @job.status_histories.create!(status: @job.status, user: current_user)
      log_activity("#{current_user.name} created job: #{@job.title}")
      redirect_to jobs_path, notice: "Job '#{@job.title}' created."
    else
      @recruiters = User.kept.where(role: "recruiter", active: true)
      render :new, status: :unprocessable_entity
    end
  end
  def edit
    existing_count = @job.job_openings.count

    if existing_count < @job.openings
      ((existing_count + 1)..@job.openings).each do |i|
        @job.job_openings.build(sequence_no: i)
      end
    end
    @recruiters = User.kept.where(role: "recruiter", active: true)
  end
  def update
    old_status = @job.status
    if @job.update(job_params)
      update_recruiters
      if @job.status != old_status
        @job.status_histories.create!(status: @job.status, user: current_user)
        updates = {}

        updates[:close_date] = @job.job_openings.first&.closed_date || Date.current if @job.status == "Closed"
        updates[:reopen_date] = Date.current if @job.status == "Reopened"
        updates[:onhold_notes] = "" if @job.status == "Closed"
        updates[:closing_notes] = "" if @job.status == "On-Hold"

        @job.update_columns(updates)
      end
      log_activity("#{current_user.name} updated job: #{@job.title}")
      redirect_to jobs_path, notice: "Job updated."
    else
      @recruiters = User.kept.where(role: "recruiter", active: true)
      render :edit, status: :unprocessable_entity
    end
  end
  def update_status
    new_status = params[:status]
    return redirect_to jobs_path unless Job::STATUSES.include?(new_status)
    updates = {}

    updates[:status] = new_status
    updates[:close_date] = Date.current if new_status == "Closed"
    updates[:reopen_date] = Date.current if new_status == "Reopened"
    updates[:onhold_notes] = "" if new_status == "Closed"
    updates[:closing_notes] = "" if new_status == "On-Hold"

    @job.update!(updates)
    @job.status_histories.create!(status: new_status, user: current_user)
    log_activity("#{current_user.name} changed #{@job.title} to #{new_status}")
    redirect_to jobs_path, notice: "Status updated to #{new_status}."
  end
  def destroy
    require_admin!
    @job.discard
    log_activity("#{current_user.name} deleted job: #{@job.title}")
    redirect_to jobs_path, notice: "Job deleted."
  end
  private
  def set_job
    @job = current_user.visible_jobs.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to jobs_path, alert: "Job not found."
  end
  def job_params
    params.require(:job).permit(:title,:company,:department,:hiring_manager,:position_type,
      :replacing_employee,:openings,:status,:open_date,:description,:skills_list,
      :experience_years,:ctc_budget,:naukri_url, :job_type, :stipend, :closing_notes,
      :onhold_notes, :interview_type, job_openings_attributes: [
      :id,
      :sequence_no,
      :closed_date,
      :onboarded_date,
      :_destroy
    ])
  end
  def update_recruiters
    ids = params[:job][:recruiter_ids]&.reject(&:blank?) || []
    @job.job_recruiters.destroy_all
    ids.each { |uid| @job.job_recruiters.create!(user_id: uid) }
  end
end
