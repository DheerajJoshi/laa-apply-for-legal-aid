Rails.application.routes.draw do
  root to: 'home#index'

  resources :status, only: [:index]

  namespace 'v1' do
    resources :proceeding_types, only: [:index]
    resources :applications, only: %i[create show] do
      resource :applicant, only: %i[create update]
    end
    resources :applicants, only: [:show] do
      resources :addresses, only: [:create]
    end
  end

  namespace :citizens do
    resources :legal_aid_applications, only: [:show]
    resource :consent, only: [:show]
    resource :information, only: [:show]
  end

  namespace :providers do
    root to: 'start#index'
    resources :legal_aid_applications, path: 'applications', only: %i[index new create] do
      resource :applicant
    end
  end
end
