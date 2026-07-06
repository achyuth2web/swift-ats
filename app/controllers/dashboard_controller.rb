class DashboardController < ApplicationController
  before_action :require_current_user!
  # before_action :require_admin!
  def index
    @candidates    = current_user.admin? ? Candidate.kept : current_user.visible_candidates
    @jobs          = current_user.admin? ? Job.kept.includes(:job_openings) : current_user.visible_jobs.includes(:recruiters, :candidates, :job_openings)
    @interviews    = Interview.kept
    @recruiters    = User.kept.where(role: "recruiter", active: true)
    @activity_logs = ActivityLog.recent.includes(:user)
    @statuses      = Candidate::STATUSES.index_with { |s| @candidates.where(status: s).count }
    @open_jobs     = @jobs.open.count
    @closed_jobs   = @jobs.closed.count
    @reopened_jobs = @jobs.reopened.count
    ttc = @jobs.select(&:time_to_close)
    @avg_tth       = ttc.any? ? (ttc.sum(&:time_to_close) / ttc.size).round : nil
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
