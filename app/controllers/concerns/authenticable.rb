module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
  end

  private

  def authenticate_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header&.start_with?('Bearer ')

    if token.present?
      decoded = JsonWebToken.decode(token)

      if decoded[:error].present?
        render_unauthorized(decoded[:error])
      else
        @current_user = User.find_by(id: decoded[:user_id])
        render_unauthorized('Invalid token') unless @current_user
      end
    else
      render_unauthorized('Missing token')
    end
  end

  def current_user
    @current_user
  end

  def render_unauthorized(message)
    render json: {
      error: {
        code: 'UNAUTHORIZED',
        message: message
      }
    }, status: :unauthorized
  end
end