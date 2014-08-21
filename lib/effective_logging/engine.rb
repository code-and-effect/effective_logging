module EffectiveLogging
  class Engine < ::Rails::Engine
    engine_name 'effective_logging'

    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]

    # Set up our default configuration options.
    initializer "effective_logging.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/lib/generators/templates/effective_logging.rb")
    end

    initializer 'effective_logging.log_email' do |app|
      ActionMailer::Base.register_interceptor(Effective::EmailLogger)
    end

    initializer 'effective_logging.setup_log_macros' do |app|
      raise ArgumentError.new("EffectiveLogging.statuses must be an Array") unless EffectiveLogging.statuses.kind_of?(Array)
      raise ArgumentError.new("EffectiveLogging.statuses must not contain 'last'") if EffectiveLogging.statuses.map(&:to_s).include?('last')

      EffectiveLogging.statuses.each do |status|
        # We want to create macro methods for each type of status on the Log (class) and Effective::Log (instance) objects
        EffectiveLogger.class.send(:define_method, status) do |message, options={}|
          log(message, status, options)
        end

        Effective::Log.instance_eval do
          send(:define_method, status) do |message, options={}|
            log(message, status, options)
          end
        end
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
