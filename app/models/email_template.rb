class EmailTemplate < ApplicationRecord
  before_validation :generate_slug, if: -> { slug.blank? }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :subject, presence: true
  validates :body, presence: true

  scope :active, -> { where(active: true) }

  private

  def generate_slug
    self.slug = name.to_s.parameterize
  end
end