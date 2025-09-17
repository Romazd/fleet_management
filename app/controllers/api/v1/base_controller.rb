module Api
  module V1
    class BaseController < Api::ApplicationController
      include Authenticable
    end
  end
end