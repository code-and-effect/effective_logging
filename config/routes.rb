EffectiveLogging::Engine.routes.draw do
  scope :module => 'effective' do
    resources :logs, :only => [:create]
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
