module EffectiveLogging
  class Engine < ::Rails::Engine
    engine_name 'effective_logging'

    # Set up our default configuration options.
    initializer "effective_logging.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/lib/generators/templates/effective_logging.rb")
    end

    # ActiveAdmin (optional)
    # This prepends the load path so someone can override the assets.rb if they want.
    initializer 'effective_logging.active_admin' do
      if defined?(ActiveAdmin) && EffectiveLogging.use_active_admin == true
        ActiveAdmin.application.load_paths.unshift Dir["#{config.root}/active_admin"]
      end
    end

    # Automatically Log Emails
    initializer 'effective_logging.emails' do |app|
      if EffectiveLogging.emails_enabled == true
        require 'effective_logging/email_logger'
        ActionMailer::Base.register_interceptor(EffectiveLogging::EmailLogger)
      end
    end

    # Register the log_page_views concern so that it can be called in ActionController or elsewhere
    initializer 'effective_logging.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        ActionController::Base.extend(EffectiveLogging::LogPageViews::ActionController)
      end
    end

    # This has to be run after initialization or User hasn't been loaded yet
    config.after_initialize do
      if EffectiveLogging.user_logins_enabled == true
        ActiveSupport.on_load :active_record do
          if defined?(Devise)
            EffectiveLogging::UserLogger.create_warden_hooks()
          else
            raise ArgumentError.new("EffectiveLogging.user_logins_enabled only works with Devise")
          end
        end
      end
    end

  end
end
