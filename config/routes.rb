Rails.application.routes.draw do
  # HTML routes
  resources :vehicles

  namespace :api do
    namespace :v1 do
      # Autenticación
      post 'auth/login', to: 'auth#login'

      # Vehículos
      resources :vehicles do
        # Servicios de mantenimiento anidados bajo vehículos
        resources :maintenance_services, only: [:index, :create]
      end

      # Servicios de mantenimiento (actualización independiente)
      resources :maintenance_services, only: [:update]

      # Reportes
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