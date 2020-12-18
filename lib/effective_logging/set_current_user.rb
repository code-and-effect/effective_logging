module EffectiveLogging
  module SetCurrentUser
    module ActionController

      # Add me to your ApplicationController
      # around_action :set_effective_logging_current_user

      def set_effective_logging_current_user
        EffectiveLogging.current_user = current_user

        if block_given?
          yield
          EffectiveLogging.current_user = nil
        end
      end

    end
  end
end
