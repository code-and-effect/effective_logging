module EffectiveLogging
  module LogChangesUser

    # Add me to your ApplicationController
    # before_action :set_log_changes_user

    def set_log_changes_user
      if respond_to?(:current_user)
        EffectiveLogging.log_changes_user = current_user
      else
        raise "(effective_logging) set_log_changes_user expects a current_user() method to be available"
      end
    end

  end
end

