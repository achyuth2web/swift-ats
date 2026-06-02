# app/models/naukri_configuration.rb
class NaukriConfiguration < ApplicationRecord
  has_many :naukri_jobs, dependent: :destroy

  validates :email, presence: true
end