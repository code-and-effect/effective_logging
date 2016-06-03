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

    before_save do
      @acts_as_loggable_new_record = new_record?
      EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).saved! unless new_record?
      true
    end

    before_destroy do
      EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).destroyed!.save
      true
    end

    after_commit do
      EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).created!.save if @acts_as_loggable_new_record
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

  def logged_changes_datatable
    @logged_changes_datatable ||= Effective::Datatables::Logs.new(associated_id: id, associated_type: self.class.name)
  end

end

