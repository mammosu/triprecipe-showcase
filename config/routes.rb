Rails.application.routes.draw do
  devise_for :users
  authenticate :user do
    mount_avo
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # get "up", to: "rails/health#show", as: :rails_health_check
  get "/up", to: proc { [ 200, { "Content-Type" => "text/plain" }, [ "OK" ] ] }


  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest", to: "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker", to: "rails/pwa#service_worker", as: :pwa_service_worker

  resources :cities, only: :index

  resources :saved_recipes, only: :index
  resource :account, only: :show, controller: "accounts"
  resource :profile, only: %i[edit update]

  resources :recipes do
    post :fork, on: :member
    resources :days, except: :index, controller: "recipe_days" do
      resources :steps, except: :index, controller: "recipe_steps" do
        member do
          post :move_up
          post :move_down
        end
        resources :photos, only: :destroy, controller: "recipe_step_photos"
      end
    end

    resource :saved_recipe, only: %i[create destroy], controller: "recipes/saved_recipes"
    resources :share_tokens, only: %i[create destroy], controller: "recipes/share_tokens" do
      member { post :extend_lifespan }
    end
    resources :collaborators, only: %i[index create update destroy], controller: "recipes/collaborators"
    get "history", to: "recipes/history#index", as: :history
    resources :audit_logs, only: :index, controller: "audit_logs"
    resource :report, only: :create, controller: "recipes/reports"
    resources :versions, only: %i[index show], controller: "recipes/versions" do
      member { post :restore }
    end
  end

  # Collaborator invitation acceptance routes
  resources :collaborator_invitations, only: [ :show ], param: :token do
    member do
      post :accept
      post :decline
    end
  end

  get "share/:token", to: "share_tokens#show", as: :share_recipe

  # Defines the root path route ("/")
  root "home#index"
  get "faq", to: "home#faq"
end
