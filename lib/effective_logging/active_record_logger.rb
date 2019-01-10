module EffectiveLogging
  class ActiveRecordLogger
    attr_accessor :object, :resource, :logger, :depth, :include_associated, :include_nested, :log_parents, :options

    BLANK = "''"

    def initialize(object, options = {})
      raise ArgumentError.new('options must be a Hash') unless options.kind_of?(Hash)

      @object = object
      @resource = Effective::Resource.new(object)

      @logger = options.fetch(:logger, object)
      @depth = options.fetch(:depth, 0)
      @include_associated = options.fetch(:include_associated, true)
      @include_nested = options.fetch(:include_nested, true)
      @log_parents = options.fetch(:log_parents, true)
      @options = options

      raise ArgumentError.new('logger must respond to logged_changes') unless @logger.respond_to?(:logged_changes)
    end

    def execute!
      @logged = false

      if new_record?(object)
        created!
      elsif destroyed_record?(object)
        destroyed!
      else
        updated!
      end

      logged?
    end

    def destroyed!
      log('Deleted', applicable(instance_attributes))
    end

    def created!
      log('Created', applicable(instance_attributes))
    end

    def updated!
      log_resource_changes!
      log_nested_resources!

      (logged? && depth == 0) ? log('Updated', applicable(instance_attributes)) : true
    end

    def log_resource_changes!
      applicable(resource.instance_changes).each do |attribute, (before, after)|
        if object.respond_to?(:log_changes_formatted_value)
          before = object.log_changes_formatted_value(attribute, before) || before
          after = object.log_changes_formatted_value(attribute, after) || after
        end

        before = before.to_s if before.kind_of?(ActiveRecord::Base) || before.kind_of?(FalseClass)
        after = after.to_s if after.kind_of?(ActiveRecord::Base) || after.kind_of?(FalseClass)

        attribute = if object.respond_to?(:log_changes_formatted_attribute)
          object.log_changes_formatted_attribute(attribute)
        end || attribute.titleize

        log("#{attribute}: #{before.presence || BLANK} &rarr; #{after.presence || BLANK}", { attribute: attribute, before: before, after: after })
      end
    end

    def log_nested_resources!
      return unless include_nested

      # Log changes on all accepts_as_nested_parameters has_many associations
      resource.nested_resources.each do |association|
        title = association.name.to_s.singularize.titleize

        Array(object.send(association.name)).each_with_index do |child, index|
          next unless child.present?

          child_options = options.merge(logger: logger, depth: depth+1, prefix: "#{title} #{index} - #{child} - ", include_associated: include_associated, include_nested: include_nested)
          child_options = child_options.merge(child.log_changes_options) if child.respond_to?(:log_changes_options)

          @logged = true if ActiveRecordLogger.new(child, child_options).execute!
        end
      end
    end

    def log(message, details)
      log = logger.logged_changes.build(
        user: EffectiveLogging.current_user,
        status: EffectiveLogging.log_changes_status,
        message: "#{"\t" * depth}#{options[:prefix]}#{message}",
        associated_to_s: (logger.to_s rescue nil),
        details: (details.presence || {})
      )

      log_changes_to_parents(message, details) if depth == 0 && log_parents

      @logged = log.save!
      log
    end

    def log_changes_to_parents(message, details)
      log_changes_parents.each do |parent|
        title = object.class.name.to_s.singularize.titleize
        parent_options = { logger: parent, prefix: "#{title} - #{object} - " }
        ActiveRecordLogger.new(parent, parent_options).log(message, details)
      end
    end

    private

    def logged?
      @logged == true
    end

    def instance_attributes # effective_resources gem
      resource.instance_attributes(include_associated: include_associated, include_nested: include_nested)
    end

    # A parent is a belongs_to that accepts_nested_attributes for this resource
    def log_changes_parents
      resource.belong_tos.map do |association|
        parent_klass = (association.options[:polymorphic] ? object.public_send(association.name).class : association.klass)

        # Skip if the parent doesn't log_changes
        next unless parent_klass.respond_to?(:log_changes)

        # Skip unless the parent accepts_nested_attributes
        next unless Effective::Resource.new(parent_klass).nested_resources.find { |ass| ass.plural_name == resource.plural_name }

        parent = object.public_send(association.name).presence

        # Sanity check
        next unless parent.respond_to?(:log_changes_options)

        # Skip if the parent does not log its nested or associated items
        next unless parent.log_changes_options[:include_nested] || parent.log_changes_options[:include_associated]

        parent
      end.compact
    end

    # TODO: Make this work better with nested objects
    def applicable(attributes)
      atts = if options[:only].present?
        attributes.stringify_keys.slice(*options[:only])
      elsif options[:except].present?
        attributes.stringify_keys.except(*options[:except])
      else
        attributes.except(:updated_at, :created_at, 'updated_at', 'created_at')
      end

      (options[:additionally] || []).each do |attribute|
        value = (object.send(attribute) rescue :effective_logging_nope)
        next if attributes[attribute].present? || value == :effective_logging_nope

        atts[attribute] = value
      end

      # Blacklist
      atts.except(:logged_changes, :trash, :updated_at, 'logged_changes', 'trash', 'updated_at')
    end

    def new_record?(object)
      return true if object.respond_to?(:new_record?) && object.new_record?
      return true if object.respond_to?(:id_was) && object.id_was.nil?
      return true if object.respond_to?(:previous_changes) && object.previous_changes.key?('id') && object.previous_changes['id'].first.nil?
      false
    end

    def destroyed_record?(object)
      return true if object.respond_to?(:destroyed?) && object.destroyed?
      return true if object.respond_to?(:marked_for_destruction?) && object.marked_for_destruction?
      return true if object.respond_to?(:previous_changes) && object.previous_changes.key?('id') && object.previous_changes['id'].last.nil?
      false
    end
  end

end
