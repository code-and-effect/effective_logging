module EffectiveLogging
  class Engine < ::Rails::Engine
    engine_name 'effective_logging'

    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]

    # Set up our default configuration options.
    initializer "effective_logging.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/lib/generators/templates/effective_logging.rb")
    end

    # Include Helper to base application
    # And extend LogPageViews concern
    initializer 'effective_orders.action_controller_helper' do |app|
      ActiveSupport.on_load :action_controller do
        helper EffectiveLoggingHelper
      end
    end

    # For each EffectiveLogging.status, such as 'success' create a EffectiveLogger.success() and Effective::Log.new().success() macro
    # We want to create macro methods for each type of status on the EffectiveLogger (class) and Effective::Log (instance) objects
    initializer 'effective_logging.effective_logger_macros' do |app|
      raise ArgumentError.new("EffectiveLogging.additional_statuses must not contain 'last'") if EffectiveLogging.statuses.include?('last')

      EffectiveLogging.statuses.each do |status|
        EffectiveLogger.singleton_class.instance_eval do
          self.send(:define_method, status) { |message, options={}| log(message, status, options) }
        end

        Effective::Log.instance_eval do
          send(:define_method, status) { |message, options={}| log(message, status, options) }
        end
      end
    end

    # Log Emails
    initializer 'effective_logging.emails' do |app|
      if EffectiveLogging.emails_enabled == true
        ActionMailer::Base.register_interceptor(Effective::EmailLogger)
      end
    end

    # Log User Logins
    initializer 'effective_logging.user_logins' do |app|
      if EffectiveLogging.user_logins_enabled == true
        if defined?(Devise) && (User.new().respond_to?(:after_database_authentication) rescue false)
          User.instance_eval do
            alias_method :original_after_database_authentication, :after_database_authentication
            send(:define_method, :after_database_authentication) { Effective::UserLogger.successful_login(self) ; original_after_database_authentication() }
          end
        else
          raise ArgumentError.new("EffectiveLogging.user_logins_enabled only works with Devise and a user class defined as User")
        end
      end
    end

    # Log Page Views
    initializer 'effective_logging.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        ActionController::Base.extend(LogPageViews::ActionController::ClassMethods)
        ActionController::Base.include(LogPageViews::ActionController::InstanceMethods)

        if EffectiveLogging.page_views_enabled
          ApplicationController.instance_eval do
            log_page_views EffectiveLogging.page_views
          end
        end
        #ApplicationController.send(:log_page_views, EffectiveLogging.page_views) if EffectiveLogging.page_views_enabled
      end
    end

  end
end
