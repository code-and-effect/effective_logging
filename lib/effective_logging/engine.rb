module EffectiveLogging
  class Engine < ::Rails::Engine
    engine_name 'effective_logging'

    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]

    # Set up our default configuration options.
    initializer "effective_logging.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/lib/generators/templates/effective_logging.rb")
    end

    # Automatically Log Emails
    initializer 'effective_logging.emails' do |app|
      if EffectiveLogging.emails_enabled == true
        ActionMailer::Base.register_interceptor(Effective::EmailLogger)
      end
    end

    # Automatically Log User Logins
    initializer 'effective_logging.user_logins' do |app|
      if EffectiveLogging.user_logins_enabled == true
        ActiveSupport.on_load :active_record do
          if defined?(Devise)
            User.instance_eval do
              alias_method :original_after_database_authentication, :after_database_authentication
              send(:define_method, :after_database_authentication) { Effective::UserLogger.successful_login(self) ; original_after_database_authentication() }
            end
          else
            raise ArgumentError.new("EffectiveLogging.user_logins_enabled only works with Devise and a user class defined as User")
          end
        end
      end
    end

    # Register the log_page_views concern so that it can be called in ActionController or elsewhere
    initializer 'effective_logging.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        ActionController::Base.extend(LogPageViews::ActionController)
      end
    end

  end
end
