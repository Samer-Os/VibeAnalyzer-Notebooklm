class Dataset < ApplicationRecord
  belongs_to :user
  has_many :research_sessions

  has_one_attached :file

  validates :name, presence: true
  
  # Metadata fields:
  # - row_count
  # - column_count
  # - variables (jsonb)
end
