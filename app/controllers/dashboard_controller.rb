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
    load_job_application_counts
  end

  def load_email_hub_stats
    mailbox = ENV.fetch("RECRUITMENT_MAILBOX", "jobs@spritle.com")

    messages = EmailMessage.where(mailbox: mailbox)

    incoming = messages.where(direction: "incoming")
                      .includes(application: :job)
                      .to_a

    outgoing = messages.where(direction: "outgoing")
                      .includes(application: :job)
                      .to_a

    if current_user.admin?
      visible_incoming = incoming
      visible_outgoing = outgoing
    else
      visible_incoming = incoming.select do |message|
        email_matches_recruiter?(message)
      end

      matched_thread_ids = visible_incoming.filter_map(&:thread_id).uniq

      visible_outgoing = outgoing.select do |message|
        job = message.application&.job

        (job && job_assigned_to_current_user?(job)) ||
          matched_thread_ids.include?(message.thread_id)
      end
    end

    @total_emails_received = visible_incoming.count do |message|
      message.status == "received" && message.application_id.blank?
    end
    @total_emails_sent = visible_outgoing.size

    @emails_rejected = visible_incoming.count do |message|
      message.status == "rejected"
    end

    @emails_moved_to_applications = visible_incoming.count do |message|
      message.application_id.present?
    end
  end

  private

  def email_matches_recruiter?(message)
    # Converted emails should use the associated application's job.
    job = message.application&.job

    return job_assigned_to_current_user?(job) if job

    EmailJobMatcher.new(message).matched_jobs.any? do |matched_job|
      job_assigned_to_current_user?(matched_job)
    end
  end

  def job_assigned_to_current_user?(job)
    job.recruiters.exists?(id: current_user.id)
  end

  def load_job_application_counts
    incoming_emails = EmailMessage.where(direction: "incoming")

    # Admin sees all emails; recruiter sees only their assigned emails.
    emails = if current_user.admin?
              incoming_emails
            else
              incoming_emails.where(assigned_to_id: current_user.id)
            end

    # Received emails
    @emails_received = if current_user.admin?
                              incoming_emails
                                .where(status: "received",
                                        assigned_to_id: nil,
                                        application_id: nil)
                                .count
                            else
                              emails.where(status: "received").count
                            end

    # Shortlisted emails
    @emails_shortlisted = emails.where(application_status: "shortlisted").count

    # Rejected emails
    @emails_rejected = emails.where(application_status: "rejected").count

    # Emails under review
    @emails_under_review = emails.where(application_status: "under_review").count
  end
end
