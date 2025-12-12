Rails.application.routes.draw do
  # E-commerce API endpoints
  namespace :api do
    resources :products, only: [:index, :show]
    resources :orders, only: [:index, :create]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
