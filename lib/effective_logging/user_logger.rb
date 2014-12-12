module EffectiveLogging
  class UserLogger
    def self.create_warden_hooks
      Warden::Manager.after_authentication do |user, warden, opts|
        EffectiveLogger.success('user login',
          :user => user,
          :ip => warden.request.ip.presence,
          :referrer => warden.request.referrer,
          :user_agent => warden.request.user_agent
        )
      end

      Warden::Manager.before_logout do |user, warden, opts|
        if user.respond_to?(:timedout?) && user.respond_to?(:timeout_in)
          scope = opts[:scope]
          last_request_at = (warden.request.session["warden.#{scope}.#{scope}.session"]['last_request_at'] rescue Time.zone.now)

          # As per Devise
          if last_request_at.is_a? Integer
            last_request_at = Time.at(last_request_at).utc
          elsif last_request_at.is_a? String
            last_request_at = Time.parse(last_request_at)
          end

          if user.timedout?(last_request_at) && !warden.request.env['devise.skip_timeout']
            EffectiveLogger.success('user logout', :user => user, :timedout => true)
          else
            EffectiveLogger.success('user logout', :user => user)
          end
        else # User does not respond to timedout
          EffectiveLogger.success('user logout', :user => user)
        end
      end

    end
  end
end
