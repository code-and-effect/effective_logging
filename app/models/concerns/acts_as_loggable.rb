module ActsAsLoggable
  extend ActiveSupport::Concern

  module ActiveRecord
    def log_changes(*options)
      @acts_as_loggable_options = options.try(:first) || {}

      unless @acts_as_loggable_options.kind_of?(Hash)
        raise ArgumentError.new('invalid arguments passed to (effective_logging) log_changes. Example usage: log_changes except: [:created_at]')
      end

      if (unknown = (@acts_as_loggable_options.keys - [:only, :except, :additionally, :include_associated, :include_nested])).present?
        raise ArgumentError.new("unknown keyword: #{unknown.join(', ')}")
      end

      include ::ActsAsLoggable
    end
  end

  included do
    has_many :logged_changes, -> { order(:id).where(status: EffectiveLogging.log_changes_status) }, as: :associated, class_name: 'Effective::Log'

    log_changes_options = {
      only: Array(@acts_as_loggable_options[:only]).map { |attribute| attribute.to_s },
      except: Array(@acts_as_loggable_options[:except]).map { |attribute| attribute.to_s },
      additionally: Array(@acts_as_loggable_options[:additionally]).map { |attribute| attribute.to_s },
      include_associated: @acts_as_loggable_options.fetch(:include_associated, true),
      include_nested: @acts_as_loggable_options.fetch(:include_nested, true)
    }

    if name == 'User'
      log_changes_options[:except] += %w(sign_in_count current_sign_in_at current_sign_in_ip last_sign_in_at last_sign_in_ip encrypted_password remember_created_at reset_password_token invitation_sent_at invitation_created_at invitation_token)
    end

    self.send(:define_method, :log_changes_options) { log_changes_options }

    after_create(unless: -> { EffectiveLogging.supressed? }) do
      ::EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).execute!
    end

    after_destroy(unless: -> { EffectiveLogging.supressed? }) do
      ::EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).execute!
    end

    after_update(unless: -> { EffectiveLogging.supressed? }) do
      ::EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).execute!
    end
  end

  module ClassMethods
  end

  # Regular instance methods

  # Format the title of this attribute. Return nil to use the default attribute.titleize
  def log_changes_formatted_attribute(attribute)
    if attribute == 'roles_mask' && defined?(EffectiveRoles) && respond_to?(:roles)
      'Roles'
    end
  end

  # Format the value of this attribute. Return nil to use the default to_s
  def log_changes_formatted_value(attribute, value)
    if attribute == 'roles_mask' && defined?(EffectiveRoles) && respond_to?(:roles)
      EffectiveRoles.roles_for(value)
    end
  end

  def log_changes_datatable
    return nil unless persisted?

    @log_changes_datatable ||= (
      EffectiveLogsDatatable.new(associated_id: id, associated_type: self.class.name, log_changes: true, status: false)
    )
  end

  def refresh_datatables
    @refresh_datatables ||= [:effective_logs]
  end

end

