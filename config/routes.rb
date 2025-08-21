Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    passwords: "users/passwords",
    omniauth_callbacks: "users/omniauth_callbacks"
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
      get :search_items
    end
  end
  resources :notifications, only: [ :index ] do
    collection do
      delete :destroy_all
    end
  end
  resources :users, only: [ :show ] do
    member do
      get :edit_profile
      patch :update_profile
    end
  end
  resources :stretch_distances, only: [] do
    collection do
      get :measure
      post :analyze
    end
    member do
      get :result
      post :create_post_with_result
    end
  end

  resource :static, only: [] do
    collection do
      get "terms_of_service"
      get "privacy_policy"
    end
  end

  # リマインダー設定
  get "reminder_settings", to: "reminder_settings#show"

  # LINE通知連携解除
  delete "/line/notification/disconnect", to: "line_webhook#disconnect", as: :line_notification_disconnect

  # LINE Messaging API Webhook / 連携リンク
  post "/line/webhook", to: "line_webhook#callback"
  get "/line/link", to: "line_webhook#link"
end
