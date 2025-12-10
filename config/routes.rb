Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end

  root 'pages#home'

  resource :dashboard, only: [:show], controller: 'dashboard'
  get 'settings', to: 'settings#index', as: :settings
  get 'about', to: 'pages#about', as: :about

  resources :projects do
    resources :tasks do
      member do
        patch :move
      end
    end
    resources :boards do
      resources :columns, only: [:create, :update, :destroy]
    end
    resources :documents
    resources :project_members, only: [:create, :destroy]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
