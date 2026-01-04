Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post 'auth/login', to: 'authentication#login'
      
      get 'users/me', to: 'users#me'
      resources :users
      
      resources :projects do
        resources :messages, only: [:index, :create] do
          collection do
            get :uploaded_files
            get :generated_files
            delete '/', to: 'messages#destroy', as: :clear
          end
        end
        
        resources :reports, only: [:index, :show, :create, :destroy]
        
        get 'dataset/all_uploaded_files', to: 'datasets#all_uploaded_files'
      end
      
      resources :datasets, only: [:index, :create, :show, :destroy] do
        member do
          get :analyze
        end
      end
      resources :research_sessions, only: [:index, :create, :show] do
        resources :messages, only: [:index, :create]
        member do
          post :recommend_methods
        end
      end
      resources :recommendations, only: [:show]
    end
  end
end
