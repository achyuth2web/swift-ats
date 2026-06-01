class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable
  ROLES = %w[admin recruiter].freeze
  has_many :job_recruiters, foreign_key: :user_id, dependent: :destroy
  has_many :jobs, through: :job_recruiters
  has_many :owned_candidates, class_name: "Candidate", foreign_key: :recruiter_id, dependent: :nullify
  has_many :activity_logs, dependent: :nullify
  validates :name, presence: true
  validates :role, inclusion: { in: ROLES }

  def admin?    = role == "admin"
  def recruiter? = role == "recruiter"
  def initials
    name.split.map(&:first).first(2).join.upcase
  end
  def visible_jobs
    admin? ? Job.all : jobs
  end
  def visible_candidates
    if admin?
      Candidate.all
    else
      my_job_ids = visible_jobs.pluck(:id)
      Candidate.where(recruiter_id: id).or(Candidate.where(job_id: my_job_ids))
    end
  end
  def visible_interviews
    admin? ? Interview.all : Interview.where(candidate_id: visible_candidates.select(:id))
  end
end
