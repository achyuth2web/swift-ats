class CalendarsController < ApplicationController
  before_action :authenticate_user!
  
  def index
  base_scope = current_user.visible_interviews
                        .left_joins(candidate: :job)
                        .where(candidates: { discarded_at: nil })
                        .where("jobs.discarded_at IS NULL OR jobs.id IS NULL")
  @interviews = base_scope.where(
                    scheduled_at: params[:start]..params[:end]
                  )

  respond_to do |format|
    format.html
    format.json do
      render json: @interviews.map { |interview|
        {
          id: interview.id,
          title: "#{interview.candidate.name} - #{interview.round_name}",
          start: interview.scheduled_at,
          end: interview.scheduled_at + 30.minutes,
          url: candidate_path(interview.candidate),
          source: interview.calendar_provider.present? ? interview.calendar_provider : "ats"
        }
      }
    end
  end
end
end