module EffectiveLogging
  class ActiveRecordLogger
    attr_accessor :object, :resource, :logger, :include_associated, :include_nested, :options

    BLANK = "''"
    BLACKLIST = [:updated_at, :created_at, :encrypted_password, :status_steps] # Don't log changes or attributes

    def initialize(object, options = {})
      raise ArgumentError.new('options must be a Hash') unless options.kind_of?(Hash)

      @object = object
      @resource = Effective::Resource.new(object)

      @logger = options.fetch(:logger, object)
      @include_associated = options.fetch(:include_associated, true)
      @include_nested = options.fetch(:include_nested, true)
      @options = options

      raise ArgumentError.new('logger must respond to logged_changes') unless @logger.respond_to?(:logged_changes)
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

      message = (['Updated'] + changes.map do |attribute, (before, after)|
        "#{attribute}: #{before.presence || BLANK} &rarr; #{after.presence || BLANK}"
      end).join("\n")

      log(message, resource_attributes.merge(changes: changes))
    end

    def log(message, details)
      logger.logged_changes.build(
        user: EffectiveLogging.current_user,
        status: EffectiveLogging.log_changes_status,
        message: [options[:prefix].presence, message].compact.join(' '),
        associated_to_s: (logger.to_s rescue nil),
        details: (details.presence || {})
      ).tap { |log| log.save! }
    end

    private

    def resource_attributes # effective_resources gem
      applicable(resource.instance_attributes(include_associated: include_associated, include_nested: include_nested))
    end

    def resource_changes # effective_resources gem
      applicable(resource.instance_changes).inject({}) do |h, (attribute, (before, after))|
        if object.respond_to?(:log_changes_formatted_value)
          before = object.log_changes_formatted_value(attribute, before) || before
          after = object.log_changes_formatted_value(attribute, after) || after
        end

        before = before.to_s if before.kind_of?(ActiveRecord::Base) || before.kind_of?(FalseClass)
        after = after.to_s if after.kind_of?(ActiveRecord::Base) || after.kind_of?(FalseClass)

        attribute = if object.respond_to?(:log_changes_formatted_attribute)
          object.log_changes_formatted_attribute(attribute)
        end || attribute.titleize

        h[attribute] = [before, after]; h
      end
    end

    def applicable(attributes)
      atts = if options[:only].present?
        attributes.stringify_keys.slice(*options[:only])
      elsif options[:except].present?
        attributes.stringify_keys.except(*options[:except])
      else
        attributes
      end

      (options[:additionally] || []).each do |attribute|
        value = (object.send(attribute) rescue :effective_logging_nope)
        next if attributes[attribute].present? || value == :effective_logging_nope

        atts[attribute] = value
      end

      # Blacklist
      atts.except(*(BLACKLIST + BLACKLIST.map(&:to_s)))
    end
  end

end
