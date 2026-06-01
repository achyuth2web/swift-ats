class PipelineController < ApplicationController
  def index
    @stages = Candidate::STATUSES
    @candidates_by_stage = @stages.index_with do |s|
      current_user.visible_candidates.where(status: s).includes(:job).order(updated_at: :desc)
    end
  end
end
