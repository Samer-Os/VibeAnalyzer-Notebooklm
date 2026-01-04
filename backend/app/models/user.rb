class User < ApplicationRecord
  has_secure_password
  has_many :projects, dependent: :destroy
  
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :role, inclusion: { in: %w[student researcher admin] }, allow_nil: true
  
  # Set default role
  after_initialize :set_default_role, if: :new_record?
  
  def as_json(options = {})
    super(options.merge(except: [:password_digest]))
  end
  
  private
  
  def set_default_role
    self.role ||= 'researcher'
  end
end
