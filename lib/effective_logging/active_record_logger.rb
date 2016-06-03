module EffectiveLogging
  class ActiveRecordLogger
    attr_accessor :resource, :options

    STATUS = 'success'

    delegate :logged_changes, :attributes, :changes, :new_record?, :marked_for_destruction?, :changed?, to: :resource

    def initialize(resource, options = {})
      @resource = resource
      @options = options

      raise ArgumentError.new('options must be a Hash') unless options.kind_of?(Hash)
      raise ArgumentError.new('resource must respond to logged_changes') unless resource.respond_to?(:logged_changes)
    end

    def execute!
      binding.pry

      if new_record?
        created
      elsif marked_for_destruction?
        destroyed
      elsif changed?
        updated
      end
    end

    protected

    def created
      logged_changes.build(status: STATUS, message: 'Created', details: applicable(attributes))
    end

    def destroyed
      logged_changes.build(status: STATUS, message: 'Deleted', details: applicable(attributes))
    end

    def updated
      applicable(changes).each do |attribute, (before, after)|
        after.present? ? attribute_changed(attribute, before, after) : attribute_set(attribute, before)
      end

      logged_changes.build(status: STATUS, message: 'Updated', details: applicable(attributes))
    end

    def attribute_changed(attribute, before, after)
      logged_changes.build(
        status: STATUS,
        message: "#{attribute.titleize} changed from '#{before}' to '#{after}'",
        details: { attribute: attribute, before: before, after: after }
      )
    end

    def attribute_set(attribute, value)
      logged_changes.build(
        status: STATUS,
        message: "#{attribute.titleize} set to '#{value}'",
        details: { attribute: attribute, value: value }
      )
    end

    private

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
