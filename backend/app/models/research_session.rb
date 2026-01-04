class ResearchSession < ApplicationRecord
  belongs_to :user
  belongs_to :dataset, optional: true
  has_many :messages, dependent: :destroy
  has_many :recommendations, dependent: :destroy

  validates :title, presence: true
end
