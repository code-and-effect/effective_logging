module Effective
  class EmailLogger
    def self.delivering_email(message)
      return unless message.present?

      # Cleanup the Header
      message_header = message.header.to_s
      message_header.gsub!(";\r\n charset", '; charset')

      # Cleanup the Body
      if (message_body = message.body.to_s).include?('<html>')
        message_body.gsub!(/(\r)*\n\s*/, '')
        message_body.gsub!("<!DOCTYPE html>", '')
      end

      (message.to || []).each do |email|
        user = User.where(:email => email).first

        if user.present?
          EffectiveLogger.success("email sent: #{message.subject}", :user => user, :email => message_header + '<hr>' + message_body)
        else
          EffectiveLogger.success("email sent to #{email}: #{message.subject}", :email => message_header + '<hr>' + message_body)
        end
      end
    end

  end
end
