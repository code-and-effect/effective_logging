module Effective
  class UserLogger
    def self.successful_login(user)
      EffectiveLogger.success("user login from #{user.try(:current_sign_in_ip) || 'unknown IP'}", :user => user)
    end
  end
end
