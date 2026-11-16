class JobApplicationActivity < ApplicationRecord
  belongs_to :email_message

  belongs_to :actor,
             class_name: "User"

  belongs_to :from_user,
             class_name: "User",
             optional: true

  belongs_to :to_user,
             class_name: "User",
             optional: true

  validates :action, presence: true
end