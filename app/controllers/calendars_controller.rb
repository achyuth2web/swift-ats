class CalendarsController < ApplicationController
  before_action :authenticate_user!
  
  def index
  @interviews = Interview
                  .kept
                  .where(
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
          end: interview.scheduled_at + 1.hour,
          url: candidate_path(interview.candidate),
          source: interview.calendar_provider.present? ? interview.calendar_provider : "ats"
        }
      }
    end
  end
end
end