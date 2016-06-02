module ActsAsLoggable
  extend ActiveSupport::Concern

  module ActiveRecord
    def log_changes(*options)
      @acts_as_loggable_options = options.try(:first) || {}

      unless @acts_as_loggable_options.kind_of?(Hash)
        raise ArgumentError.new("invalid arguments passed to (effective_logging) log_changes. Example usage: log_changes except: [:created_at]")
      end

      include ::ActsAsLoggable
    end
  end

  included do
    has_many :logged_changes, as: :associated, class_name: Effective::Log
    before_save :log_changes

    # Parse Options
    log_changes_options = {
      only: Array(@acts_as_loggable_options[:only]).map { |attribute| attribute.to_s },
      except: Array(@acts_as_loggable_options[:except]).map { |attribute| attribute.to_s },
      additionally: Array(@acts_as_loggable_options[:additionally]).map { |attribute| attribute.to_s }
    }

    self.send(:define_method, :log_changes_options) { log_changes_options }
  end

  module ClassMethods
  end

  def logged_changes_datatable
    @logged_changes_datatable ||= Effective::Datatables::Logs.new(associated_id: id, associated_type: self.class.name)
  end

  def log_changes_applicable(attributes)
    atts = if log_changes_options[:only].present?
      attributes.slice(*log_changes_options[:only])
    elsif log_changes_options[:except].present?
      attributes.except(*log_changes_options[:except])
    else
      attributes
    end

    log_changes_options[:additionally].each do |attribute|
      value = (send(attribute) rescue :acts_as_loggable_nope)
      next if attributes[attribute].present? || value == :acts_as_loggable_nope

      atts[attribute] = value
    end

    atts
  end

  # Regular instance methods
  def log_changes
    if new_record?
      logged_changes.build(status: 'success', message: 'Created', details: {attributes: log_changes_applicable(attributes)})
    elsif marked_for_destruction?
      logged_changes.build(status: 'success', message: 'Deleted', details: {attributes: log_changes_applicable(attributes)})
    else
      log_changes_applicable(changes).each do |attribute, (before, after)|
        if after.present?
          logged_changes.build(
            status: 'success',
            message: "#{attribute.titleize} changed from '#{before}' to '#{after}'",
            details: { attribute: attribute, before: before, after: after }
          )
        else
          logged_changes.build(
            status: 'success',
            message: "#{attribute.titleize} set to '#{before}'",
            details: { attribute: attribute, value: before }
          )
        end
      end

      logged_changes.build(status: 'success', message: 'Updated', details: {attributes: log_changes_applicable(attributes)})
    end

    true  # Always return true, just incase
  end

end

