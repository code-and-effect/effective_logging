module EffectiveLogging
  class EmailLogger
    def self.delivering_email(message)
      return if EffectiveLogging.supressed?
      return unless message.present?
      return unless ActiveRecord::Base.connection.table_exists?(:logs)

      # collect a Hash of arguments used to invoke EffectiveLogger.success
      fields = { from: Array(message.from).join(','), to: message.to, subject: message.subject, cc: message.cc, bcc: message.bcc }

      # Add a log header to your mailer to pass some objects or additional things to EffectiveLogger
      # mail(to: 'admin@example.com', subject: @post.title, log: @post)
      log = if message.header['log'].present?
        message.header['log'].instance_variable_get(:@unparsed_value) ||
        message.header['log'].instance_variable_get(:@value)
      end

      # If we have a logged object, associate it
      if log.present?
        if log.kind_of?(ActiveRecord::Base)
          fields.merge!(associated: log)
        elsif log.kind_of?(Hash)
          fields.merge!(log)
        else
          raise('log expected an ActiveRecord object or Hash')
        end
      end

      # Read the current app's Tenant if defined
      tenant = if defined?(Tenant)
        Tenant.current || raise("Missing tenant in effective_logging email logger")
      end

      # Clean up the header
      message.header.fields.delete_if { |field| ['tenant', 'log'].include?(field.name) }

      # Parse the content for logging
      parts = (message.body.try(:parts) || []).map { |part| [part, (part.parts if part.respond_to?(:parts))] }.flatten
      body = parts.find { |part| part.content_type.to_s.downcase.include?('text/html') } || message.body
      fields[:email] = "#{message.header}<hr>#{body}"

      # Find the user to associate it with
      user_klass = (tenant ? Tenant.engine_user(tenant) : 'User'.safe_constantize)

      # Log the email
      log_email(message, fields, user_klass)

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

      true
    end

  end
end
