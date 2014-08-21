EffectiveLogging::Engine.routes.draw do
  if defined?(EffectiveDatatables)
    namespace :admin do
      resources :logs, :only => [:index, :show]
    end
  end
end

Rails.application.routes.draw do
  mount EffectiveLogging::Engine => '/', :as => 'effective_logging'
end
