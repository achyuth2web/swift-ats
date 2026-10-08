class GmailIntegration < ApplicationRecord
  validates :email, presence: true, uniqueness: true

  scope :recruitment, -> {
    where(email: ENV.fetch("RECRUITMENT_MAILBOX", "jobs@spritle.com"))
  }
end