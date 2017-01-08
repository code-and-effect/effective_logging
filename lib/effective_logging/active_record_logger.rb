module EffectiveLogging
  class ActiveRecordLogger
    attr_accessor :resource, :logger, :depth, :options

    BLANK = "''"

    def initialize(resource, options = {})
      raise ArgumentError.new('options must be a Hash') unless options.kind_of?(Hash)

      @resource = resource
      @logger = options.delete(:logger) || resource
      @depth = options.delete(:depth) || 0
      @options = options

      raise ArgumentError.new('logger must respond to logged_changes') unless @logger.respond_to?(:logged_changes)
    end

    # execute! is called when we recurse, otherwise the following methods are best called individually
    def execute!
      if resource.new_record?
        created!
      elsif resource.marked_for_destruction?
        destroyed!
      else
        changed!
      end
    end

    # before_destroy
    def destroyed!
      log('Deleted', details: applicable(attributes))
    end

    # after_commit
    def created!
      log('Created', details: applicable(attributes))
    end

    # after_commit
    def updated!
      log('Updated', details: applicable(attributes))
    end

    # before_save
    def changed!
      applicable(changes).each do |attribute, (before, after)|
        if resource.respond_to?(:log_changes_formatted_value)
          before = resource.log_changes_formatted_value(attribute, before) || before
          after = resource.log_changes_formatted_value(attribute, after) || after
        end

        attribute = if resource.respond_to?(:log_changes_formatted_attribute)
          resource.log_changes_formatted_attribute(attribute)
        end || attribute.titleize

        if after.present?
          log("#{attribute} changed from #{before.presence || BLANK} to #{after.presence || BLANK}", details: { attribute: attribute, before: before, after: after })
        else
          log("#{attribute} set to #{before || BLANK}", details: { attribute: attribute, value: before })
        end
      end

      # Log changes on all accepts_as_nested_parameters has_many associations
      (resource.class.try(:reflect_on_all_autosave_associations) || []).each do |association|
        child_name = association.name.to_s.singularize.titleize

        Array(resource.send(association.name)).each_with_index do |child, index|
          ActiveRecordLogger.new(child, options.merge(logger: logger, depth: (depth + 1), prefix: "#{child_name} ##{index+1}: ")).execute!
        end
      end
    end

    def attributes
      attributes = { attributes: resource.attributes }

      # Collect to_s representations of all belongs_to associations
      (resource.class.try(:reflect_on_all_associations, :belongs_to) || []).each do |association|
        attributes[association.name] = resource.send(association.name).to_s.presence || 'nil'
      end

      # Collect to_s representations for all has_one associations
      (resource.class.try(:reflect_on_all_associations, :has_one) || []).each do |association|
        attributes[association.name] = resource.send(association.name).to_s.presence
      end

      # Collects attributes for all accepts_as_nested_parameters has_many associations
      (resource.class.try(:reflect_on_all_autosave_associations) || []).each do |association|
        attributes[association.name] = {}

        Array(resource.send(association.name)).each_with_index do |child, index|
          attributes[association.name][index+1] = ActiveRecordLogger.new(child, options.merge(logger: logger)).attributes
        end
      end

      attributes
    end

    def changes
      changes = resource.changes

      # Log to_s changes on all belongs_to associations
      (resource.class.try(:reflect_on_all_associations, :belongs_to) || []).each do |association|
        if (change = changes.delete(association.foreign_key)).present?
          changes[association.name] = [association.klass.find_by_id(change.first), resource.send(association.name)]
        end
      end

      changes
    end

    private

    def log(message, details: {})
      logger.logged_changes.build(
        user: EffectiveLogging.current_user,
        status: EffectiveLogging.log_changes_status,
        message: "#{"\t" * depth}#{options[:prefix]}#{message}",
        details: details
      ).tap { |log| log.save }
    end

    # TODO: Make this work better with nested objects
    def applicable(attributes)
      atts = if options[:only].present?
        attributes.slice(*options[:only])
      elsif options[:except].present?
        attributes.except(*options[:except])
      else
        attributes.except(:updated_at, :created_at)
      end

      (options[:additionally] || []).each do |attribute|
        value = (resource.send(attribute) rescue :effective_logging_nope)
        next if attributes[attribute].present? || value == :effective_logging_nope

        atts[attribute] = value
      end

      atts
    end

  end
end
