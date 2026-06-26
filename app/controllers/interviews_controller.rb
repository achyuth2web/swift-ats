class InterviewsController < ApplicationController
  before_action :set_interview, only: [:edit, :update, :destroy]
  def index
    # @interviews = current_user.visible_interviews.order(Arel.sql("scheduled_at ASC NULLS LAST")).includes(candidate: [:job])
    base_scope = current_user.visible_interviews
                         .left_joins(candidate: :job)
                         .where(candidates: { discarded_at: nil })
                         .where("jobs.discarded_at IS NULL OR jobs.id IS NULL")

    base_scope = base_scope.where(status: params[:status]) if params[:status].present?
    base_scope = base_scope.where(candidates: { job_id: params[:job_id] }) if params[:job_id].present?

    @interviews = Interview
                    .from(
                      base_scope.select(
                        "interviews.*,
                        ROW_NUMBER() OVER (
                          PARTITION BY candidate_id
                          ORDER BY scheduled_at DESC NULLS LAST
                        ) AS rn"
                      ),
                      :interviews
                    )
                    .where("rn = 1")
                    .includes(candidate: :job)
                    .order("scheduled_at ASC NULLS LAST")
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
