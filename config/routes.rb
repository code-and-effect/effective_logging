EffectiveLogging::Engine.routes.draw do
  scope :module => 'effective' do
    # Create is our javascript POST event for EffectiveLogging from JS side
    # The show and index routes are for user specific logs
    resources :logs, :only => [:create, :show, :index]
  end

  if defined?(EffectiveDatatables)
    namespace :admin do
      resources :logs, :only => [:index, :show]
    end
  end

end

Rails.application.routes.draw do
  mount EffectiveLogging::Engine => '/', :as => 'effective_logging'
end
