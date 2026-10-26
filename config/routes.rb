Rails.application.routes.draw do
  resources :products
  resources :orders, only: %i[ index show create ] do
    post :apply_coupon, on: :member
    post :apply, on: :member
    post :redeem, on: :member
    resource :coupon, only: [:create], controller: "coupons"
    resources :coupons, only: [:create], controller: "coupons"
  end
  resources :coupons, only: [:create], controller: "coupons"
  resources :payouts, only: :index do
    post :simulate, on: :collection
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get "up" => "rails/health#show", as: :rails_health_check
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "pwa#service_worker", as: :service_worker

  # Defines the root path route ("/")
  root "products#index"
end