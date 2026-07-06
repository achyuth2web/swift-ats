class ReportsController < ApplicationController
  before_action :require_admin!
  def index
    @jobs       = Job.kept.includes(:candidates, :job_openings)
    @candidates = Candidate.kept
    @recruiters = User.kept.where(role: "recruiter", active: true)
    ttc = @jobs.select(&:time_to_close)
    @avg_ttc  = ttc.any? ? (ttc.sum(&:time_to_close) / ttc.size).round : nil
    @ttc_jobs = ttc.sort_by(&:time_to_close)
    tto = @jobs.select(&:time_to_onboard)
    @avg_tto  = tto.any? ? (tto.sum(&:time_to_onboard) / tto.size).round : nil
    @tto_jobs = tto.sort_by(&:time_to_onboard)
    @source_counts  = Candidate::SOURCES.map { |s| [s, @candidates.where(source: s).count] }.to_h
    @dept_counts    = Candidate::DEPARTMENTS.map { |d| [d, @candidates.where(department: d).count] }.to_h
    @status_counts  = Candidate::STATUSES.index_with { |s| @candidates.where(status: s).count }
    @recruiter_stats = @recruiters.map do |r|
      rc = @candidates.where(recruiter_id: r.id)
      { user: r, candidates: rc.count, hired: rc.where(status: %w[Offer Hired]).count }
    end
  end
end
