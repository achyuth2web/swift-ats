class InterviewFeedbacksController < ApplicationController
  layout "public"
  skip_before_action :authenticate_user!, raise: false
  before_action :set_interview

  def show
  end

  def update
    if @interview.update(feedback_params.merge(feedback_submitted_at: Time.current))
      redirect_to interview_feedback_path(@interview.feedback_token), notice: "Feedback submitted. Thank you!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_interview
    @interview = Interview.kept.find_by(feedback_token: params[:token])
    render "invalid", status: :not_found unless @interview
  end

  def feedback_params
    params.require(:interview).permit(:status, :outcome, :rating, :feedback)
  end
end
