class DashboardController < ApplicationController
  before_action :require_admin!
  def index
    @candidates    = Candidate.all
    @jobs          = Job.all
    @interviews    = Interview.all
    @recruiters    = User.where(role: "recruiter", active: true)
    @activity_logs = ActivityLog.recent.includes(:user)
    @statuses      = Candidate::STATUSES.index_with { |s| @candidates.where(status: s).count }
    @open_jobs     = @jobs.open.count
    @closed_jobs   = @jobs.closed.count
    @reopened_jobs = @jobs.reopened.count
    tth = @jobs.select(&:time_to_hire)
    @avg_tth       = tth.any? ? (tth.sum(&:time_to_hire) / tth.size).round : nil
    @recent_candidates = @candidates.order(created_at: :desc).limit(5).includes(:job)
    @recruiter_stats = @recruiters.map do |r|
      rc = @candidates.where(recruiter_id: r.id)
      rj = @jobs.joins(:job_recruiters).where(job_recruiters: { user_id: r.id })
      iv = @interviews.where(candidate_id: rc.pluck(:id))
      { user: r, candidates: rc.count, hired: rc.where(status: %w[Offer Hired]).count,
        interviews: iv.count, jobs: rj.count }
    end
  end
end
