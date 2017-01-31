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
    has_many :logged_changes, -> { where(status: EffectiveLogging.log_changes_status) }, as: :associated, class_name: Effective::Log

    around_save do |_, block|
      @acts_as_loggable_new_record = new_record?
      EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).changed! unless @acts_as_loggable_new_record
      block.call
      true
    end

    before_destroy do
      EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).destroyed!
      true
    end

    after_commit do
      if @acts_as_loggable_new_record
        EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).created!
      else
        EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).updated!
      end
      true
    end

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

  # Regular instance methods

  # Format the title of this attribute. Return nil to use the default attribute.titleize
  def log_changes_formatted_attribute(attribute)
    # Intentionally does nothing
  end

  # Format the value of this attribute. Return nil to use the default to_s
  def log_changes_formatted_value(attribute, value)
    # Intentionally does nothing
  end

  def log_changes_datatable
    if persisted?
      @log_changes_datatable ||= (
        Effective::Datatables::Logs.new(associated_id: id, associated_type: self.class.name, log_changes: true, status: false)
      )
    end
  end

end

