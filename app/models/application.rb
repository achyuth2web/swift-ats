class Application < ApplicationRecord
  belongs_to :candidate, optional: true
  belongs_to :job, optional: true

  belongs_to :assigned_to,
             class_name: "User",
             foreign_key: :assigned_to_id,
             optional: true

  has_many :email_messages, dependent: :nullify

  enum :status, {
    open: "open",
    in_progress: "in_progress",
    interview: "interview",
    offer: "offer",
    rejected: "rejected",
    closed: "closed"
  }
end