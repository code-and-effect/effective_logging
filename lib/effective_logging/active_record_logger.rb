module EffectiveLogging
  class ActiveRecordLogger
    attr_accessor :resource, :logger, :options

    def initialize(resource, options = {})
      @resource = resource
      @logger = options.delete(:logger) || resource
      @options = options

      binding.pry

      raise ArgumentError.new('options must be a Hash') unless options.kind_of?(Hash)
      raise ArgumentError.new('logger must respond to logged_changes') unless logger.respond_to?(:logged_changes)
    end

    def execute!
      if resource.new_record?
        created
      elsif resource.marked_for_destruction?
        destroyed
      elsif resource.changed?
        updated
      else
        # No action
      end
    end

    protected

    def created
      log('Created', applicable(resource.attributes))
    end

    def destroyed
      log('Deleted', applicable(resource.attributes))
    end

    def updated
      applicable(resource.changes).each do |attribute, (before, after)|
        if after.present?
          log("#{attribute.titleize} changed from '#{before}' to '#{after}'", { attribute: attribute, before: before, after: after })
        else
          log("#{attribute.titleize} set to '#{value}'", { attribute: attribute, value: value })
        end
      end

      # Log changes on all accepts_as_nested_parameters has_many associations
      (resource.class.try(:reflect_on_all_autosave_associations) || []).each do |association|
        child_name = association.name.to_s.singularize.titleize

        resource.send(association.name).each_with_index do |child, index|
          ActiveRecordLogger.new(child, options.merge(logger: logger, prefix: "#{child_name} ##{index}: ")).execute!
        end

      end

      log('Updated', applicable(resource.attributes))
    end

    private

    def log(message, details = {})
      logger.logged_changes.build(status: 'success', message: "#{options[:prefix]}#{message}", details: details)
    end

    def applicable(attributes)
      atts = if options[:only].present?
        attributes.slice(*options[:only])
      elsif options[:except].present?
        attributes.except(*options[:except])
      else
        attributes
      end

      options[:additionally].each do |attribute|
        value = (resource.send(attribute) rescue :effective_logging_nope)
        next if attributes[attribute].present? || value == :effective_logging_nope

        atts[attribute] = value
      end

      atts
    end

  end
end
