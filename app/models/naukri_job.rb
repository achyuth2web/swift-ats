# app/models/naukri_job.rb
class NaukriJob < ApplicationRecord
  belongs_to :naukri_configuration
  belongs_to :job, optional: true

  validates :title, presence: true
end