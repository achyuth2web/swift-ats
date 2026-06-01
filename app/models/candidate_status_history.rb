class CandidateStatusHistory < ApplicationRecord
  belongs_to :candidate
  belongs_to :user, optional: true
end
