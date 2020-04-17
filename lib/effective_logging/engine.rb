require 'effective_logging/active_record_logger'

module EffectiveLogging
  class Engine < ::Rails::Engine
    engine_name 'effective_logging'

    config.autoload_paths += Dir["#{config.root}/lib/"]

    # Set up our default configuration options.
    initializer "effective_logging.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_logging.rb")
    end

    # Automatically Log Emails
    initializer 'effective_logging.emails' do |app|
      if EffectiveLogging.email_enabled == true
        require 'effective_logging/email_logger'
        ActionMailer::Base.register_interceptor(EffectiveLogging::EmailLogger)
      end
    end

    # Include acts_as_loggable concern and allow any ActiveRecord object to call it with log_changes()
    initializer 'effective_logging.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(ActsAsLoggable::Base)
      end
    end

    # Register the log_page_views concern so that it can be called in ActionController or elsewhere
    initializer 'effective_logging.log_changes_action_controller' do |app|
      Rails.application.config.to_prepare do
        ActiveSupport.on_load :action_controller do
          require 'effective_logging/set_current_user'
          ActionController::Base.include(EffectiveLogging::SetCurrentUser::ActionController)
        end
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
      if EffectiveLogging.sign_in_enabled || EffectiveLogging.sign_out_enabled
        ActiveSupport.on_load :active_record do
          EffectiveLogging::UserLogger.create_warden_hooks()
        end
      end
    end

  end
end
