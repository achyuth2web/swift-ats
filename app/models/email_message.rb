class EmailMessage < ApplicationRecord
  belongs_to :application, optional: true
  belongs_to :candidate, optional: true
  belongs_to :assigned_to,
           class_name: "User",
           optional: true
  has_many :job_application_activities,
           dependent: :nullify

  enum :direction, {
    incoming: "incoming",
    outgoing: "outgoing"
  }

  enum :status, {
    received: "received",
    sent: "sent",
    failed: "failed",
    rejected: "rejected"
  }

  validates :message_id, presence: true, uniqueness: true
  validates :from_email, presence: true
  validates :application_status,
            inclusion: {
              in: %w[shortlisted under_review rejected forwarded],
              allow_nil: true
            }
end