# frozen_string_literal: true

module ActsAsLoggable
  extend ActiveSupport::Concern

  module Base
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
    has_many :logged_changes, -> { where(status: EffectiveLogging.log_changes_status).order(:id) }, as: :changes_to, class_name: 'Effective::Log'

    log_changes_options = {
      to: @acts_as_loggable_options[:to],
      prefix: @acts_as_loggable_options[:prefix],
      only: Array(@acts_as_loggable_options[:only]),
      except: Array(@acts_as_loggable_options[:except])
    }

    if name.end_with?('User')
      log_changes_options[:except] += %i(sign_in_count current_sign_in_at current_sign_in_ip last_sign_in_at last_sign_in_ip encrypted_password remember_created_at reset_password_token invitation_sent_at invitation_created_at invitation_token access_token refresh_token token_expires_at)
    end

    self.send(:define_method, :log_changes_options) { log_changes_options }

    after_create(if: -> { log_changes? }, unless: -> { EffectiveLogging.supressed? }) do
      ::EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).created!
    end

    after_destroy(if: -> { log_changes? }, unless: -> { EffectiveLogging.supressed? }) do
      ::EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).destroyed!
    end

    after_update(if: -> { log_changes? }, unless: -> { EffectiveLogging.supressed? }) do
      ::EffectiveLogging::ActiveRecordLogger.new(self, log_changes_options).updated!
    end
  end

  module ClassMethods
    def acts_as_loggable?; true; end
  end

  # Regular instance methods

  # Disable logging of changes for this resource
  def log_changes?
    true # Can be overridden to suppress logging
  end

  # Format the title of this attribute. Return nil to use the default attribute.titleize
  def log_changes_formatted_attribute(attribute)
    'Roles' if attribute == :roles_mask && defined?(EffectiveRoles) && respond_to?(:roles)
  end

  # Format the value of this attribute. Return nil to use the default to_s
  def log_changes_formatted_value(attribute, value)
    EffectiveRoles.roles_for(value) if attribute == :roles_mask && defined?(EffectiveRoles) && respond_to?(:roles)
  end

  def logs_datatable
    EffectiveLogsDatatable.new(for: self) if persisted?
  end

  def log_changes_datatable
    # We use the changes_to_type and changes_to_id so that the bootstrap3 datatable is still aware of the resources
    EffectiveLogChangesDatatable.new(changes_to: self, changes_to_type: self.class.name, changes_to_id: id) if persisted?
  end

end
