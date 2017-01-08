module EffectiveLogging
  module LogChangesUser

    # Add me to your ApplicationController
    # before_action :set_effective_logging_current_user

    def set_effective_logging_current_user
      if respond_to?(:current_user)
        EffectiveLogging.current_user = current_user
      else
        raise "(effective_logging) set_effective_logging_current_user expects a current_user() method to be available"
      end
    end

  end
end

