class CandidatesController < ApplicationController
  before_action :set_candidate, only: [:show, :edit, :update, :destroy, :update_status]
  def index
    @candidates = current_user.visible_candidates.search(params[:q]).order(created_at: :desc).includes(:job, :recruiter)
    @candidates = @candidates.where(department: params[:dept])   if params[:dept].present?
    @candidates = @candidates.where(status: params[:status])     if params[:status].present?
    @candidates = @candidates.where(job_id: params[:job_id])     if params[:job_id].present?
    @all_count  = current_user.visible_candidates.count
    @candidates = @candidates.page(params[:page]).per(10)
    @jobs       = current_user.visible_jobs.order(:title)
  end
  def show
    @interviews     = @candidate.interviews.order(:round_number, :scheduled_at)
    @job            = @candidate.job
    @status_history = @candidate.status_histories.order(created_at: :desc).includes(:user)
  end
  def new
    @candidate  = Candidate.new
    @jobs       = current_user.visible_jobs
    @recruiters = User.where(role: "recruiter", active: true) if admin?
  end
  def create
    @candidate = Candidate.new(candidate_params)
    @candidate.recruiter ||= current_user unless admin?
    if @candidate.save
      @candidate.status_histories.create!(status: @candidate.status, user: current_user)
      log_activity("#{current_user.name} added candidate: #{@candidate.name}")
      redirect_to candidates_path, notice: "Candidate added."
    else
      @jobs = current_user.visible_jobs
      @recruiters = User.where(role: "recruiter", active: true) if admin?
      render :new, status: :unprocessable_entity
    end
  end
  def edit
    @jobs       = current_user.visible_jobs
    @recruiters = User.where(role: "recruiter", active: true) if admin?
  end
  def update
    if @candidate.update(candidate_params)
      log_activity("#{current_user.name} updated candidate: #{@candidate.name}")
      redirect_to candidates_path, notice: "Candidate updated."
    else
      @jobs = current_user.visible_jobs
      @recruiters = User.where(role: "recruiter", active: true) if admin?
      render :edit, status: :unprocessable_entity
    end
  end
  def update_status
    new_status = params[:status]
    return redirect_to candidates_path unless Candidate::STATUSES.include?(new_status)
    old_status = @candidate.status
    @candidate.update!(status: new_status)
    @candidate.status_histories.create!(status: new_status, note: "Changed from #{old_status}", user: current_user)
    log_activity("#{current_user.name} moved #{@candidate.name} to #{new_status}")
    redirect_to candidate_path(@candidate), notice: "Status updated to #{new_status}."
  end
  def destroy
    name = @candidate.name
    if @candidate.soft_delete!
      log_activity("#{current_user.name} deleted candidate: #{name}")
      redirect_to candidates_path, notice: "Candidate deleted."
    else
      redirect_to candidates_path, alert: "Unable to delete candidate."
    end
  end
  private
  def set_candidate
    @candidate = current_user.visible_candidates.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to candidates_path, alert: "Not found or access denied."
  end
  def candidate_params
    params.require(:candidate).permit(:name,:email,:phone,:role,:department,:designation,
      :skills_list,:experience_years,:status,:score,:source,:ctc_current,:ctc_expected,
      :ctc_unit,:notice_period,:notes,:job_id,:recruiter_id,:resume)
  end
end
