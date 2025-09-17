Rails.application.routes.draw do
  resources :vehicles do
    resources :maintenance_services, except: [:show]
  end

  namespace :api do
    namespace :v1 do
      post 'auth/login', to: 'auth#login'

      resources :vehicles do
        resources :maintenance_services, only: [:index, :create]
      end

      resources :maintenance_services, only: [:update]

      namespace :reports do
        get :maintenance_summary
      end
    end
  end

  # Root path
  root 'vehicles#index'

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end