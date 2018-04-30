module EffectiveLogging
  class UserLogger
    def self.create_warden_hooks
      Warden::Manager.after_authentication do |user, warden, opts|
        if EffectiveLogging.sign_in_enabled && !EffectiveLogging.supressed?
          ::EffectiveLogger.sign_in('Sign in', user: user, associated: user, request: warden.request)
        end
      end

      Warden::Manager.after_set_user do |user, warden, opts|
        if EffectiveLogging.sign_in_enabled && !EffectiveLogging.supressed?
          if opts && opts[:event] == :set_user && !opts.key?(:store) # User has just reset their password and signed in
            ::EffectiveLogger.sign_in('Sign in', user: user, associated: user, request: warden.request, notes: 'after password reset')
          end
        end
      end

      Warden::Manager.before_logout do |user, warden, opts|
        if EffectiveLogging.sign_out_enabled && !EffectiveLogging.supressed?
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
              ::EffectiveLogger.sign_out('Sign out', user: user, associated: user, timedout: true)
            else
              ::EffectiveLogger.sign_out('Sign out', user: user, associated: user)
            end
          else # User does not respond to timedout
            ::EffectiveLogger.sign_out('Sign out', user: user, associated: user)
          end
        end
      end

    end
  end
end
