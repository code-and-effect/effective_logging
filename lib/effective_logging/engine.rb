module EffectiveLogging
  class Engine < ::Rails::Engine
    engine_name 'effective_logging'

    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]

    # Set up our default configuration options.
    initializer "effective_logging.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/lib/generators/templates/effective_logging.rb")
    end

    initializer 'effective_logging.effective_logger_macros' do |app|
      raise ArgumentError.new("EffectiveLogging.additional_statuses must not contain 'last'") if EffectiveLogging.statuses.include?('last')

      EffectiveLogging.statuses.each do |status|
        # We want to create macro methods for each type of status on the Log (class) and Effective::Log (instance) objects
        EffectiveLogger.class.send(:define_method, status) { |message, options={}| log(message, status, options) }

        Effective::Log.instance_eval do
          send(:define_method, status) { |message, options={}| log(message, status, options) }
        end
      end
    end

    initializer 'effective_logging.log_email' do |app|
      if EffectiveLogging.emails_enabled == true
        ActionMailer::Base.register_interceptor(Effective::EmailLogger)
      end
    end



    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    # initializer 'effective_logging.active_record' do |app|
    #   ActiveSupport.on_load :active_record do
    #     ActiveRecord::Base.extend(ActsAsObfuscated::ActiveRecord)
    #   end
    # end
  end
end
