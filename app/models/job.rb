class Job < ApplicationRecord
  include Discard::Model
  has_many :job_recruiters, dependent: :destroy
  has_many :recruiters, through: :job_recruiters, source: :user
  has_many :candidates, dependent: :nullify
  has_many :status_histories, class_name: "JobStatusHistory", dependent: :destroy
  has_many :job_openings, dependent: :destroy

  accepts_nested_attributes_for :job_openings, allow_destroy: true
  STATUSES       = %w[Open Closed Reopened].freeze
  DEPARTMENTS    = %w[Tech HR Sales Finance Operations Marketing].freeze
  POSITION_TYPES = %w[New Replacement].freeze
  JOB_TYPES      = %w[Full-Time Intern Consultant].freeze
  validates :title, presence: true, length: { minimum: 5, maximum: 50 }
  validates :status, inclusion: { in: STATUSES }
  def skills
    (skills_list || "").split(",").map(&:strip).reject(&:empty?)
  end
  def time_to_hire
    return nil unless hire_date && open_date
    (hire_date - open_date).to_i
  end
  def candidate_count = candidates.kept.count
  scope :open,     -> { where(status: "Open") }
  scope :closed,   -> { where(status: "Closed") }
  scope :reopened, -> { where(status: "Reopened") }

  before_save :clear_irrelevant_compensation

  private

  def clear_irrelevant_compensation
    if job_type == "Full-Time"
      self.stipend = nil
    else
      self.ctc_budget = nil
    end
  end
end
