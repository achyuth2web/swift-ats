class InterviewsController < ApplicationController
  before_action :set_interview, only: [:edit, :update, :destroy]
  def index
    # @interviews = current_user.visible_interviews.order(Arel.sql("scheduled_at ASC NULLS LAST")).includes(candidate: [:job])
    @interviews = current_user.visible_interviews
                          .left_joins(candidate: :job)
                          .where(candidates: { discarded_at: nil })
                          .where("jobs.discarded_at IS NULL OR jobs.id IS NULL")
                          .includes(candidate: :job)
                          .order(Arel.sql("scheduled_at ASC NULLS LAST"))
    @interviews = @interviews.where(status: params[:status]) if params[:status].present?
    if params[:job_id].present?
      @interviews = @interviews.joins(candidate: :job)
                              .where(candidates: { job_id: params[:job_id] })
    end
  end
  def new
    @interview  = Interview.new(round_number: 1, candidate_id: params[:candidate_id])
    @candidates = current_user.visible_candidates.order(:name)
  end
  def create
    @interview = Interview.new(interview_params)
    if @interview.save
      log_activity("Interview scheduled: #{@interview.round_name} for #{@interview.candidate.name}")
      redirect_to interviews_path, notice: "Interview scheduled."
    else
      @candidates = current_user.visible_candidates.order(:name)
      render :new, status: :unprocessable_entity
    end
  end
  def edit
    @candidates = current_user.visible_candidates.order(:name)
  end
  def update
    if @interview.update(interview_params)
      log_activity("Interview updated: #{@interview.round_name} for #{@interview.candidate.name}")
      redirect_to interviews_path, notice: "Interview updated."
    else
      @candidates = current_user.visible_candidates.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @interview.discard
    log_activity("#{current_user.name} deleted interview for #{@interview.candidate.name}")
    redirect_to interviews_path, notice: "Interview deleted."
  end
  private
  def set_interview
    @interview = current_user.visible_interviews.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to interviews_path, alert: "Not found."
  end
  def interview_params
    params.require(:interview).permit(:candidate_id,:round_name,:round_number,:interviewer,
      :scheduled_at,:status,:outcome,:feedback,:rating)
  end
end
