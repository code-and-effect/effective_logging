module EffectiveLogging
  class ActiveRecordLogger
    attr_accessor :resource, :logger, :depth, :options

    def initialize(resource, options = {})
      @resource = resource
      @logger = options.delete(:logger) || resource
      @depth = options.delete(:depth) || 0
      @options = options

      raise ArgumentError.new('options must be a Hash') unless options.kind_of?(Hash)
      raise ArgumentError.new('logger must respond to logged_changes') unless logger.respond_to?(:logged_changes)
    end

    def execute!
      if resource.new_record?
        created!
      elsif resource.marked_for_destruction?
        destroyed!
      else
        saved!
      end
    end

    def created!
      log('Created', applicable(attributes))
    end

    def destroyed!
      log('Deleted', applicable(attributes))
    end

    def saved!
      applicable(changes).each do |attribute, (before, after)|
        if after.present?
          log("#{attribute.titleize} changed from '#{before}' to '#{after}'", { attribute: attribute, before: before, after: after })
        else
          log("#{attribute.titleize} set to '#{before}'", { attribute: attribute, value: before })
        end
      end

      # Log changes on all accepts_as_nested_parameters has_many associations
      (resource.class.try(:reflect_on_all_autosave_associations) || []).each do |association|
        child_name = association.name.to_s.singularize.titleize

        resource.send(association.name).each_with_index do |child, index|
          ActiveRecordLogger.new(child, options.merge(logger: logger, depth: (depth + 1), prefix: "#{child_name} ##{index+1}: ")).execute!
        end
      end

      log('Updated', applicable(attributes)) if depth == 0
    end

    def attributes
      attributes = { attributes: resource.attributes }

      # Collect to_s representations of all belongs_to associations
      (resource.class.try(:reflect_on_all_associations, :belongs_to) || []).each do |association|
        attributes[association.name] = resource.send(association.name).to_s.presence || 'nil'
      end

      # Collect to_s representations for all has_one associations
      (resource.class.try(:reflect_on_all_associations, :has_one) || []).each do |association|
        attributes[association.name] = resource.send(association.name).to_s.presence || 'nil'
      end

      # Collects attributes for all accepts_as_nested_parameters has_many associations
      (resource.class.try(:reflect_on_all_autosave_associations) || []).each do |association|
        attributes[association.name] = {}

        resource.send(association.name).each_with_index do |child, index|
          attributes[association.name][index+1] = ActiveRecordLogger.new(child, options.merge(logger: logger)).attributes
        end
      end

      attributes
    end

    def changes
      changed = resource.changes

      # Log to_s changes on all belongs_to associations
      (resource.class.try(:reflect_on_all_associations, :belongs_to) || []).each do |association|
        if (change = changed.delete(association.foreign_key)).present?
          changed[association.name] = [association.klass.find_by_id(change.first), resource.send(association.name)]
        end
      end

      changed
    end

    private

    def log(message, details = {})
      logger.logged_changes.build(status: 'success', message: "#{"\t" * depth}#{options[:prefix]}#{message}", details: details)
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
