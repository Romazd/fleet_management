module Api
  module V1
    class BaseController < ActionController::API
      include Authenticable
    end
  end
end