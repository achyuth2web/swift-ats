class Interview < ApplicationRecord
  include Discard::Model
  belongs_to :candidate
  STATUSES = ["Scheduled","Completed","No Show","Cancelled"].freeze
  OUTCOMES = %w[Pending Pass Rejected Hold].freeze
  validates :round_name, presence: true
  def scheduled_display
    scheduled_at&.strftime("%d %b %Y, %I:%M %p") || "—"
  end
end
