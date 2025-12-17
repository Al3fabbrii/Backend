Rails.application.routes.draw do
  # E-commerce API endpoints
  namespace :api do
    # Auth endpoints (JWT)
    post 'auth/login', to: 'auth#login'
    post 'auth/logout', to: 'auth#logout'
    get 'auth/me', to: 'auth#me'
    post 'auth/register', to: 'auth#register'

    # Public endpoints
    resources :products, only: [:index, :show]


    # Protected endpoints (require authentication)
    resources :orders, only: [:index, :create]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
