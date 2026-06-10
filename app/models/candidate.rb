class Candidate < ApplicationRecord
  include Discard::Model
  belongs_to :job,       optional: true
  belongs_to :recruiter, class_name: "User", foreign_key: :recruiter_id, optional: true
  has_many :interviews, dependent: :destroy
  has_many :status_histories, class_name: "CandidateStatusHistory", dependent: :destroy
  STATUSES    = %w[New Screening Interview Offer Rejected Hired].freeze
  SOURCES     = ["LinkedIn","Naukri","Referral","Job Board","Other"].freeze
  DEPARTMENTS = %w[Tech HR Sales Finance Operations Marketing].freeze
  validates :name,   presence: true, length: { minimum: 5, maximum: 50 }
  validates :email,  presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone,
          format: {
            with: /\A\d+\z/,
            message: "must contain only numbers"
          },
          allow_blank: true
  validates :ctc_current,
            numericality: {
              greater_than_or_equal_to: 0
            },
            allow_blank: true

  validates :ctc_expected,
            numericality: {
              greater_than_or_equal_to: 0
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
  def resume_url
    return if resume_file_key.blank?
    Uploads::S3Bucket.new.generate_presigned_url(resume_file_key)
  end
  def soft_delete!
    update_column(
      :email,
      "discarded_#{id}_#{Time.current.to_i}_#{email}"
    )
    discard
  end
  def delete_resume_from_s3
    return if resume_file_key.blank?

    Uploads::S3Bucket.new.delete_file(resume_file_key)

    update_column(:resume_file_key, nil)
  rescue => e
    Rails.logger.error("Failed to delete resume from S3 for Candidate #{id}: #{e.message}")
    false
  end
  def show_feedback
    interview = interviews.kept.order(created_at: :desc).first
    return "No Feedback Available" unless interview&.feedback.present?
    interview.feedback
  end
end
