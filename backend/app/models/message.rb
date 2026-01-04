class Message < ApplicationRecord
  belongs_to :project
  has_one :report, dependent: :destroy
  has_many_attached :files
  
  enum :role, { user: 'user', assistant: 'assistant' }
  
  validates :content, presence: true
  
  # Default empty array for file_ids
  after_initialize do
    self.file_ids ||= []
  end
end
