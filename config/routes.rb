Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
    }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "home#index"

  resource :goal, only: %i[new create edit update]
  resources :boards, only: %i[index new create show edit update destroy] do
    resource :cheer, only: %i[create destroy]
    resources :bookmarks, only: %i[create destroy]
    collection do
      get :bookmarks
    end
  end
  resources :notifications, only: [:index] do
    collection do
      delete :destroy_all
    end
  end
  resources :users, only: %i[show]
end
