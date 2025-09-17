class User < ApplicationRecord
  has_secure_password

  # Validations
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: :password_required?

  # Callbacks
  before_validation :normalize_email

  # JWT token generation
  def generate_jwt
    JWT.encode(
      {
        user_id: id,
        email: email,
        exp: 24.hours.from_now.to_i
      },
      Rails.application.credentials.secret_key_base
    )
  end

  def self.decode_jwt(token)
    decoded = JWT.decode(
      token,
      Rails.application.credentials.secret_key_base,
      true,
      { algorithm: 'HS256' }
    )
    decoded.first
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  private

  def normalize_email
    self.email = email&.strip&.downcase
  end

  def password_required?
    password_digest.nil? || password.present?
  end
end