class Report < ApplicationRecord
  belongs_to :message
  has_one_attached :pdf_file
  has_one_attached :zip_file
  
  validates :status, presence: true
end
