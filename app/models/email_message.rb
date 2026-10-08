class EmailMessage < ApplicationRecord
  belongs_to :application, optional: true
  belongs_to :candidate, optional: true

  enum :direction, {
    incoming: "incoming",
    outgoing: "outgoing"
  }

  enum :status, {
    received: "received",
    sent: "sent",
    failed: "failed"
  }

  validates :message_id, presence: true, uniqueness: true
  validates :from_email, presence: true
end