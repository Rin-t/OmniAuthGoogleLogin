Rails.application.routes.draw do
  use_doorkeeper
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  get  "/auth/:provider/callback", to: "sessions#create"
  get  "/auth/failure",            to: "sessions#failure"
  delete "/logout",                to: "sessions#destroy", as: :logout

  namespace :api do
    namespace :v1 do
      get "me", to: "me#show"
    end
  end
end
