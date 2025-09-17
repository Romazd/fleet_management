require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  describe 'POST /api/v1/auth/login' do
    let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    context 'with valid credentials' do
      it 'returns a JWT token and user info' do
        post '/api/v1/auth/login', params: {
          email: 'test@example.com',
          password: 'password123'
        }

        expect(response).to have_http_status(:success)

        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['user']).to include(
          'id' => user.id,
          'email' => user.email,
          'name' => user.name
        )

        # Verify token is valid
        decoded = JsonWebToken.decode(json['token'])
        expect(decoded[:user_id]).to eq(user.id)
        expect(decoded[:email]).to eq(user.email)
      end

      it 'is case-insensitive for email' do
        post '/api/v1/auth/login', params: {
          email: 'TEST@EXAMPLE.COM',
          password: 'password123'
        }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized with wrong password' do
        post '/api/v1/auth/login', params: {
          email: 'test@example.com',
          password: 'wrongpassword'
        }

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json['error']).to include(
          'code' => 'INVALID_CREDENTIALS',
          'message' => 'Invalid email or password'
        )
      end

      it 'returns unauthorized with non-existent email' do
        post '/api/v1/auth/login', params: {
          email: 'nonexistent@example.com',
          password: 'password123'
        }

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json['error']).to include(
          'code' => 'INVALID_CREDENTIALS',
          'message' => 'Invalid email or password'
        )
      end

      it 'returns unauthorized with missing parameters' do
        post '/api/v1/auth/login', params: {}

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end
    end

    context 'token expiration' do
      it 'generates a token with correct expiration' do
        post '/api/v1/auth/login', params: {
          email: 'test@example.com',
          password: 'password123'
        }

        json = JSON.parse(response.body)
        decoded = JWT.decode(
          json['token'],
          Rails.application.credentials.secret_key_base,
          true,
          { algorithm: 'HS256' }
        ).first

        exp_time = Time.at(decoded['exp'])
        expect(exp_time).to be > Time.now
        expect(exp_time).to be <= 24.hours.from_now
      end
    end
  end
end