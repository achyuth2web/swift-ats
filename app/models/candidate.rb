class Candidate < ApplicationRecord
  belongs_to :job,       optional: true
  belongs_to :recruiter, class_name: "User", foreign_key: :recruiter_id, optional: true
  has_many :interviews, dependent: :destroy
  has_many :status_histories, class_name: "CandidateStatusHistory", dependent: :destroy
  STATUSES    = %w[New Screening Interview Offer Rejected Hired].freeze
  SOURCES     = ["LinkedIn","Naukri","Referral","Job Board","Other"].freeze
  DEPARTMENTS = %w[Tech HR Sales Finance Operations Marketing].freeze
  validates :name,   presence: true
  validates :email,  presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone,
          format: {
            with: /\A\+?[\d\s\-()]{10,20}\z/,
            message: "is not a valid phone number"
          },
          allow_blank: true
  validates :status, inclusion: { in: STATUSES }
  def skills
    (skills_list || "").split(",").map(&:strip).reject(&:empty?)
  end
  def ctc_display
    return "—" unless ctc_current.present? || ctc_expected.present?
    "#{ctc_current || '?'} → #{ctc_expected || '?'} #{ctc_unit || 'LPA'}"
  end
  def notice_display
    notice_period.present? ? "#{notice_period} days" : "—"
  end
  scope :search, ->(q) {
    return all unless q.present?
    where("name ILIKE :q OR email ILIKE :q OR role ILIKE :q OR skills_list ILIKE :q", q: "%#{q}%")
  }
end
