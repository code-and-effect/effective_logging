# frozen_string_literal: true

EffectiveLogging::Engine.routes.draw do
  scope module: 'effective' do
    # Create is our javascript POST event for EffectiveLogging from JS side
    # The show and index routes are for user specific logs
    resources :logs, only: [:create, :index, :show] do
      member { get :html_part }
    end
  end

  namespace :admin do
    resources :logs, only: [:index, :show]
    resources :tracks, only: :index
  end

end

Rails.application.routes.draw do
  mount EffectiveLogging::Engine => '/', :as => 'effective_logging'
end
