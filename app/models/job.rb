class Job < ApplicationRecord
  include Discard::Model
  has_many :job_recruiters, dependent: :destroy
  has_many :recruiters, through: :job_recruiters, source: :user
  has_many :candidates, dependent: :nullify
  has_many :status_histories, class_name: "JobStatusHistory", dependent: :destroy
  has_many :job_openings, dependent: :destroy

  accepts_nested_attributes_for :job_openings, allow_destroy: true
  STATUSES       = %w[Open Closed Reopened On-Hold].freeze
  DEPARTMENTS    = %w[Tech HR Sales Finance Operations Marketing].freeze
  POSITION_TYPES = %w[New Replacement].freeze
  JOB_TYPES      = %w[Full-Time Intern Consultant].freeze
  validates :title, presence: true, length: { minimum: 5, maximum: 50 }
  validates :status, inclusion: { in: STATUSES }
  def skills
    (skills_list || "").split(",").map(&:strip).reject(&:empty?)
  end
  def time_to_close
    average_days_to(:closed_date)
  end

  def time_to_onboard
    average_days_to(:onboarded_date)
  end

  def close_to_onboard_time
    average_days_to_onboard(:onboarded_date)
  end

  def candidate_count = candidates.kept.count
  scope :open,     -> { where(status: "Open") }
  scope :closed,   -> { where(status: "Closed") }
  scope :reopened, -> { where(status: "Reopened") }

  before_save :clear_irrelevant_compensation

  private

  def average_days_to(date_column)
    return nil unless open_date
    days = job_openings.filter_map { |o| (o.public_send(date_column) - open_date).to_i if o.public_send(date_column) }
    return nil if days.empty?
    (days.sum / days.size.to_f).round
  end

  def average_days_to_onboard(date_column)
    return nil unless close_date
    days = job_openings.filter_map { |o| (o.public_send(date_column) - (o.closed_date || close_date)).to_i if o.public_send(date_column) }
    return nil if days.empty?
    (days.sum / days.size.to_f).round
  end

  def clear_irrelevant_compensation
    if job_type == "Full-Time"
      self.stipend = nil
    else
      self.ctc_budget = nil
    end
  end
end
