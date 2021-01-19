module EffectiveLogging
  class EmailLogger
    def self.delivering_email(message)
      return if EffectiveLogging.supressed?
      return unless message.present?

      # collect a Hash of arguments used to invoke EffectiveLogger.success
      logged_fields = { from: message.from.join(','), to: message.to, subject: message.subject, cc: message.cc, bcc: message.bcc }

      # Add a log header to your mailer to pass some objects or additional things to EffectiveLogger
      # mail(to: 'admin@example.com', subject: @post.title, log: { post: @post })
      if message.header['log'].present?
        # This is a bit sketchy, but gives access to the object in Rails 4.2 anyway
        logged_fields.merge!(message.header['log'].instance_variable_get(:@value) || {})

        # Get rid of the extra header, as it should not be set in the real mail message.
        message.header['log'] = nil
      end

      body = (message.body.try(:parts) || []).find { |part| part.content_type.to_s.downcase.include?('text/html') }
      to = Array(message.to) - [nil, '']

      logged_fields[:email] = "#{message.header}<hr>#{(body.presence || message.body)}"

      to.each do |to|
        user = (User.where(email: to).first rescue nil)

        logged_fields[:to] = to
        logged_fields[:associated] ||= user
        logged_fields[:user] ||= user

        ::EffectiveLogger.email("#{message.subject} - #{message.to.join(', ')}", logged_fields)
      end

      if to.blank? && (message.cc.present? || message.bcc.present?)
        ::EffectiveLogger.email("#{message.subject} - multiple recipients", logged_fields)
      end

    end

  end
end
