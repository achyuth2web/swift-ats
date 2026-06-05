class ReportsController < ApplicationController
  before_action :require_admin!
  def index
    @jobs       = Job.kept.includes(:candidates)
    @candidates = Candidate.kept
    @recruiters = User.where(role: "recruiter", active: true)
    tth = @jobs.select(&:time_to_hire)
    @avg_tth      = tth.any? ? (tth.sum(&:time_to_hire) / tth.size).round : nil
    @tth_jobs     = tth.sort_by(&:time_to_hire)
    @source_counts  = Candidate::SOURCES.map { |s| [s, @candidates.where(source: s).count] }.to_h
    @dept_counts    = Candidate::DEPARTMENTS.map { |d| [d, @candidates.where(department: d).count] }.to_h
    @status_counts  = Candidate::STATUSES.index_with { |s| @candidates.where(status: s).count }
    @recruiter_stats = @recruiters.map do |r|
      rc = @candidates.where(recruiter_id: r.id)
      { user: r, candidates: rc.count, hired: rc.where(status: %w[Offer Hired]).count }
    end
  end
end
