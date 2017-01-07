module EffectiveLogging
  class Engine < ::Rails::Engine
    engine_name 'effective_logging'

    config.autoload_paths += Dir["#{config.root}/lib/"]

    # Set up our default configuration options.
    initializer "effective_logging.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_logging.rb")
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

    # Include acts_as_loggable concern and allow any ActiveRecord object to call it with log_changes()
    initializer 'effective_logging.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(ActsAsLoggable::ActiveRecord)
        ActiveRecord::Base.extend(ActsAsTrashable::ActiveRecord)
      end
    end

    # Register the log_page_views concern so that it can be called in ActionController or elsewhere
    initializer 'effective_logging.log_changes_action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        ActionController::Base.include(EffectiveLogging::LogChangesUser)
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
      if EffectiveLogging.user_logins_enabled || EffectiveLogging.user_logouts_enabled
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
