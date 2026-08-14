class User < ApplicationRecord
  include Discard::Model
  devise :database_authenticatable, :rememberable, :validatable
  ROLES = %w[admin recruiter].freeze
  has_many :job_recruiters, foreign_key: :user_id, dependent: :destroy
  has_many :jobs, through: :job_recruiters
  has_many :owned_candidates, class_name: "Candidate", foreign_key: :recruiter_id, dependent: :nullify
  has_many :activity_logs, dependent: :nullify
  has_many :email_logs, dependent: :destroy
  has_many :calendar_integrations, dependent: :destroy
  validates :name, presence: true
  validates :role, inclusion: { in: ROLES }

  def admin?    = role == "admin"
  def recruiter? = role == "recruiter"
  def initials
    name.split.map(&:first).first(2).join.upcase
  end
  def active_for_authentication?
    super && kept?
  end
  def inactive_message
    discarded? ? :deleted_account : super
  end
  def visible_jobs
    admin? ? Job.kept : jobs.kept
  end
  def visible_candidates
    if admin?
      Candidate.kept
    else
      my_job_ids = visible_jobs.select(:id)

      Candidate.kept.where(recruiter_id: id)
              .or(
                Candidate.kept
                          .where(job_id: my_job_ids)
                          .where.not(recruiter_id: nil)
              )
    end
  end
  def visible_interviews
    if admin?
      Interview.kept
    else
      Interview.kept.where(candidate_id: visible_candidates.select(:id))
    end
  end
  def google_calendar_connected?
    calendar_integrations.google.exists?
  end
end
