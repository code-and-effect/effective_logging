module Effective
  class EmailLogger
    def self.delivering_email(message)
      (message.to || []).each do |email|
        user = User.where(:email => email).first

        if user.present?
          EffectiveLogger.success("email sent: #{message.subject}", :user => user, :details => message.to_s)
        else
          EffectiveLogger.success("email sent to #{email}: #{message.subject}", :user => user, :details => message.to_s)
        end
      end
    end

  end
end
