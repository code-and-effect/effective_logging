module EffectiveLogging
  module SetCurrentUser
    module ActionController

      # Add me to your ApplicationController
      # before_action :set_effective_logging_current_user

      def set_effective_logging_current_user
        EffectiveLogging.current_user = current_user
        yield if block_given?
      end

    end
  end
end
