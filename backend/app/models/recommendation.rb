class Recommendation < ApplicationRecord
  belongs_to :research_session

  # Fields:
  # - method_name
  # - description
  # - rationale
  # - evidence (jsonb)
  
  validates :method_name, presence: true
end
