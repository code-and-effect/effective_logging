module EffectiveLogging
  class ActiveRecordLogger
    attr_accessor :object, :resource, :options

    BLANK = "''"
    BLACKLIST = [:updated_at, :created_at, :encrypted_password, :status_steps] # Don't log changes or attributes

    # to, prefix, only, except
    def initialize(object, args = {})
      @object = object
      @resource = Effective::Resource.new(object)

      # Validate changes_to value
      if args[:to].present? && !@resource.belong_tos.map(&:name).include?(args[:to])
        raise ArgumentError.new("unable to find existing belongs_to relationship matching #{args[:to]}. Expected a symbol matching a belongs_to.")
      end

      @options = { to: args[:to], prefix: args[:prefix], only: args[:only], except: Array(args[:except]) + BLACKLIST }.compact
    end

    # Effective::Log.where(message: 'Deleted').where('details ILIKE ?', '%lab_test_id: 263%')
    def destroyed!
      log('Deleted', resource_attributes)
    end

    def created!
      log('Created', resource_attributes)
    end

    def updated!
      changes = resource_changes

      return true if changes.blank? # If you just click save and change nothing, don't log it.

      message = (['Updated'] + format_resource_changes(changes).map do |attribute, (before, after)|
        "#{attribute}: #{before.presence || BLANK} &rarr; #{after.presence || BLANK}"
      end).join("\n")

      log(message, resource_attributes.merge(changes: changes))
    end

    def log(message, details)
      return if object.respond_to?(:log_changes_rule) && !object.log_changes_rule(details)

      log_options = {
        changes_to: log_changes_to,
        associated: object,
        associated_to_s: (object.to_s rescue nil),
        user: EffectiveLogging.current_user,
        status: EffectiveLogging.log_changes_status,
        message: [options[:prefix].presence, message].compact.join,
        details: (details.presence || {})
      }

      if object.respond_to?(:log_changes_formatted_log)
        formatted_log = object.log_changes_formatted_log(message, details)
        log_options.merge!(formatted_log) if formatted_log
      end

      Effective::Log.create!(log_options)
    end

    private

    def log_changes_to
      logger = object

      while(logger.log_changes_options[:to].present?)
        belongs_to = logger.public_send(logger.log_changes_options[:to])
        break unless belongs_to.respond_to?(:log_changes_options)
        logger = belongs_to
      end

      logger
    end

    def resource_attributes # effective_resources gem
      resource.instance_attributes(only: options[:only], except: options[:except])
    end

    def resource_changes # effective_resources gem
      resource.instance_changes(only: options[:only], except: options[:except])
    end

    def format_resource_changes(changes)
      changes.inject({}) do |h, (attribute, (before, after))|
        if object.respond_to?(:log_changes_formatted_value)
          before = object.log_changes_formatted_value(attribute, before) || before
          after = object.log_changes_formatted_value(attribute, after) || after
        end

        before = before.to_s if before.kind_of?(ActiveRecord::Base) || before.kind_of?(FalseClass)
        after = after.to_s if after.kind_of?(ActiveRecord::Base) || after.kind_of?(FalseClass)

        attribute = if object.respond_to?(:log_changes_formatted_attribute)
          object.log_changes_formatted_attribute(attribute)
        end || attribute.to_s.titleize

        h[attribute] = [before, after]; h
      end
    end
  end

end
