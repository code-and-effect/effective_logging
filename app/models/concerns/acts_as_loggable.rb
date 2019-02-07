module ActsAsLoggable
  extend ActiveSupport::Concern

  module ActiveRecord
    def log_changes(*options)
      @acts_as_loggable_options = options.try(:first) || {}

      unless @acts_as_loggable_options.kind_of?(Hash)
        raise ArgumentError.new('invalid arguments passed to (effective_logging) log_changes. Example usage: log_changes except: [:created_at]')
      end

      if (unknown = (@acts_as_loggable_options.keys - [:to, :prefix, :only, :except])).present?
        raise ArgumentError.new("unknown keyword: #{unknown.join(', ')}")
      end

      include ::ActsAsLoggable
    end
  end

  included do
    has_many :logged_changes, -> { order(:id).where(status: EffectiveLogging.log_changes_status) }, as: :changes_to, class_name: 'Effective::Log'

    log_changes_options = {
      to: @acts_as_loggable_options[:to],
      prefix: @acts_as_loggable_options[:prefix],
      only: Array(@acts_as_loggable_options[:only]).map { |attribute| attribute.to_s },
      except: Array(@acts_as_loggable_options[:except]).map { |attribute| attribute.to_s },
    }

    if name == 'User'
      log_changes_options[:except] += %w(sign_in_count current_sign_in_at current_sign_in_ip last_sign_in_at last_sign_in_ip encrypted_password remember_created_at reset_password_token invitation_sent_at invitation_created_at invitation_token)
    end

    self.send(:define_method, :log_changes_options) { log_changes_options }

    after_create(unless: -> { EffectiveLogging.supressed? }) do
      ::EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).created!
    end

    after_destroy(unless: -> { EffectiveLogging.supressed? }) do
      ::EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).destroyed!
    end

    after_update(unless: -> { EffectiveLogging.supressed? }) do
      ::EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).updated!
    end
  end

  module ClassMethods
    def acts_as_loggable?; true; end
  end

  # Regular instance methods

  # Format the title of this attribute. Return nil to use the default attribute.titleize
  def log_changes_formatted_attribute(attribute)
    'Roles' if attribute == 'roles_mask' && defined?(EffectiveRoles) && respond_to?(:roles)
  end

  # Format the value of this attribute. Return nil to use the default to_s
  def log_changes_formatted_value(attribute, value)
    EffectiveRoles.roles_for(value) if attribute == 'roles_mask' && defined?(EffectiveRoles) && respond_to?(:roles)
  end

  def log_changes_datatable
    EffectiveLogChangesDatatable.new(changes_to_id: id, changes_to_type: self.class.name) if persisted?
  end

end

