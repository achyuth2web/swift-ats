class ActivityLog < ApplicationRecord
  belongs_to :user, optional: true
  scope :recent, -> { order(created_at: :desc).limit(100) }
end
