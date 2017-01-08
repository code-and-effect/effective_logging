module EffectiveLogging
  module SetCurrentUser
    module ActionController

      # Add me to your ApplicationController
      # before_action :set_effective_logging_current_user

      def set_effective_logging_current_user
        if respond_to?(:current_user)
          EffectiveLogging.current_user = current_user
        else
          raise "(effective_logging) set_effective_logging_current_user expects a current_user() method to be available"
        end
      end

      def set_log_changes_user
        # No longer need to call this
      end

      # Sets the before action it immediately
      def self.included(base)
        if base.respond_to?(:before_action)
          base.before_action :set_effective_logging_current_user
        else
          base.before_filter :set_effective_logging_current_user
        end
      end

    end
  end
end

