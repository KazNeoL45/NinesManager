Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end

  root 'pages#home'

  resource :dashboard, only: [:show], controller: 'dashboard'
  get 'settings', to: 'settings#index', as: :settings
  get 'about', to: 'pages#about', as: :about

  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:create, :destroy]
  end

  resources :projects do
    resources :tasks do
      member do
        patch :move
        delete 'documents/:document_id', action: :remove_document, as: :remove_document
      end
      resources :task_assignments, only: [:create, :update, :destroy]
    end
    resources :boards do
      resources :columns, only: [:create, :update, :destroy]
    end
    resources :documents
    resources :project_members, only: [:create, :destroy]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
