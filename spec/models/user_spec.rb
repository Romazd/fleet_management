require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should have_secure_password }
    it { should validate_length_of(:password).is_at_least(6) }

    it 'validates email format' do
      user = build(:user, email: 'invalid-email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'accepts valid email format' do
      user = build(:user, email: 'valid@example.com')
      expect(user).to be_valid
    end
  end

  describe 'callbacks' do
    describe '#normalize_email' do
      it 'downcases and strips email' do
        user = build(:user, email: '  TEST@EXAMPLE.COM  ')
        user.valid?
        expect(user.email).to eq('test@example.com')
      end
    end
  end

  describe '#generate_jwt' do
    let(:user) { create(:user) }

    it 'generates a valid JWT token' do
      token = user.generate_jwt
      expect(token).to be_present

      decoded = JWT.decode(
        token,
        Rails.application.credentials.secret_key_base || Rails.application.secrets.secret_key_base,
        true,
        { algorithm: 'HS256' }
      ).first

      expect(decoded['user_id']).to eq(user.id)
      expect(decoded['email']).to eq(user.email)
      expect(decoded['exp']).to be > Time.now.to_i
    end
  end

  describe '.decode_jwt' do
    let(:user) { create(:user) }

    it 'decodes a valid JWT token' do
      token = user.generate_jwt
      decoded = User.decode_jwt(token)

      expect(decoded['user_id']).to eq(user.id)
      expect(decoded['email']).to eq(user.email)
    end

    it 'returns nil for invalid token' do
      decoded = User.decode_jwt('invalid.token.here')
      expect(decoded).to be_nil
    end

    it 'returns nil for expired token' do
      token = JWT.encode(
        { user_id: user.id, exp: 1.hour.ago.to_i },
        Rails.application.credentials.secret_key_base || Rails.application.secrets.secret_key_base
      )

      decoded = User.decode_jwt(token)
      expect(decoded).to be_nil
    end
  end

  describe 'case-insensitive email uniqueness' do
    let!(:existing_user) { create(:user, email: 'test@example.com') }

    it 'prevents duplicate with different case' do
      new_user = build(:user, email: 'TEST@EXAMPLE.COM')
      expect(new_user).not_to be_valid
      expect(new_user.errors[:email]).to include('has already been taken')
    end

    it 'prevents duplicate with mixed case' do
      new_user = build(:user, email: 'TeSt@ExAmPlE.cOm')
      expect(new_user).not_to be_valid
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end
  end
end