module EffectiveLogging
  class EmailLogger
    def self.delivering_email(message)
      return if EffectiveLogging.supressed?
      return unless message.present?

      # collect a Hash of arguments used to invoke EffectiveLogger.success
      fields = { from: message.from.join(','), to: message.to, subject: message.subject, cc: message.cc, bcc: message.bcc }

      # Add a log header to your mailer to pass some objects or additional things to EffectiveLogger
      # mail(to: 'admin@example.com', subject: @post.title, log: @post)
      log = if message.header['log'].present?
        value = message.header['log'].instance_variable_get(:@unparsed_value)
        value ||= message.header['log'].instance_variable_get(:@value)
        message.header['log'] = nil
        value
      end

      if log.present?
        if log.kind_of?(ActiveRecord::Base)
          fields.merge!(associated: log)
        elsif log.kind_of?(Hash)
          fields.merge!(log)
        else
          raise('log expected an ActiveRecord object or Hash')
        end
      end

      # Pass a tenant to your mailer
      # mail(to: 'admin@example.com', subject: @post.title, tenant: Tenant.current)
      tenant = if message.header['tenant'].present?
        value = message.header['tenant'].to_s.to_sym # OptionalField, not a String here
        message.header['tenant'] = nil
        value
      end

      user_klass = "#{tenant.to_s.classify}::User".safe_constantize

      body = (message.body.try(:parts) || []).find { |part| part.content_type.to_s.downcase.include?('text/html') }
      body ||= message.body

      fields[:email] = "#{message.header}<hr>#{body}"

      if tenant.present? && defined?(Tenant)
        Tenant.as_if(tenant) { log_email(message, fields, user_klass) }
      else
        log_email(message, fields, user_klass)
      end

      true
    end

    private

    def self.log_email(message, fields, user_klass)
      tos = Array(message.to) - [nil, '']

      tos.each do |to|
        user = (user_klass.where(email: to.downcase).first if user_klass.present?)

        user_fields = fields.merge(to: to, user: user)
        ::EffectiveLogger.email("#{message.subject} - #{tos.join(', ')}", user_fields)
      end

      if tos.blank? && (message.cc.present? || message.bcc.present?)
        ::EffectiveLogger.email("#{message.subject} - multiple recipients", fields)
      end
    end

  end
end
