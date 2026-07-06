class Interview < ApplicationRecord
  include Discard::Model
  belongs_to :candidate
  has_secure_token :feedback_token
  STATUSES = ["Scheduled","Completed","No Show","Cancelled"].freeze
  OUTCOMES = %w[Pending Pass Rejected Hold].freeze
  validates :round_name, presence: true
  validates :interviewer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  def scheduled_display
    scheduled_at&.strftime("%d %b %Y, %I:%M %p") || "—"
  end
  def feedback_submitted?
    feedback_submitted_at.present?
  end
end
