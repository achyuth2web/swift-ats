class Interview < ApplicationRecord
  include Discard::Model
  belongs_to :candidate
  has_secure_token :feedback_token
  STATUSES = ["Scheduled","Completed","No Show","Cancelled"].freeze
  OUTCOMES = %w[Pending Pass Rejected Hold].freeze
  validates :round_name, presence: true
  # validates :interviewer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :validate_interviewer_emails
  before_validation :normalize_interviewer_emails
  def scheduled_display
    scheduled_at&.strftime("%d %b %Y, %I:%M %p") || "—"
  end
  def feedback_submitted?
    feedback_submitted_at.present?
  end
  def attendees
    [
      candidate&.email,
      candidate&.recruiter&.email,
      *interviewer_email.to_s.split(",").map(&:strip)
    ]
  end
  def interviewer_emails
    interviewer_email.to_s
      .split(",")
      .map(&:strip)
      .reject(&:blank?)
      .uniq
  end

  private

  def normalize_interviewer_emails
    self.interviewer_email = interviewer_emails.join(",")
  end

  def validate_interviewer_emails
    interviewer_emails.each do |email|
      unless URI::MailTo::EMAIL_REGEXP.match?(email)
        errors.add(:interviewer_email, "#{email} is not a valid email")
      end
    end
  end
end
