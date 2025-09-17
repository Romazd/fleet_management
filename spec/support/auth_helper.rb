module AuthHelper
  def auth_headers(user)
    token = JsonWebToken.encode(user_id: user.id, email: user.email)
    {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }
  end

  def invalid_auth_headers
    {
      'Authorization' => 'Bearer invalid.token.here',
      'Content-Type' => 'application/json'
    }
  end

  def expired_auth_headers(user)
    token = JWT.encode(
      { user_id: user.id, email: user.email, exp: 1.hour.ago.to_i },
      Rails.application.credentials.secret_key_base
    )
    {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json'
    }
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
end