class EmailLog < ApplicationRecord
  STATUSES = %w[pending sent failed].freeze

  belongs_to :user
  belongs_to :candidate, optional: true

  validates :recipient_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true
  validates :body, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :cc_email_format

  private

  def cc_email_format
    return if cc_email.blank?

    invalid = cc_email.split(",").map(&:strip).reject { |addr| addr.match?(URI::MailTo::EMAIL_REGEXP) }
    errors.add(:cc_email, "contains invalid address(es): #{invalid.join(', ')}") if invalid.any?
  end
end
