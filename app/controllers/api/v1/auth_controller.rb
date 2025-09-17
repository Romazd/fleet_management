module Api
  module V1
    class AuthController < ActionController::API
      def login
        user = User.find_by(email: params[:email]&.downcase)

        if user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: user.id, email: user.email)
          render json: {
            token: token,
            user: {
              id: user.id,
              email: user.email,
              name: user.name
            }
          }
        else
          render json: {
            error: {
              code: 'INVALID_CREDENTIALS',
              message: 'Invalid email or password'
            }
          }, status: :unauthorized
        end
      end
    end
  end
end