require 'effective_resources'
require 'effective_logging/engine'
require 'effective_logging/version'

module EffectiveLogging

  # The following are all valid config keys
  mattr_accessor :logs_table_name
  mattr_accessor :use_active_admin

  mattr_accessor :authorization_method
  mattr_accessor :layout
  mattr_accessor :additional_statuses

  mattr_accessor :email_enabled
  mattr_accessor :sign_in_enabled
  mattr_accessor :sign_out_enabled

  def self.setup
    yield self
  end

  def self.authorized?(controller, action, resource)
    if authorization_method.respond_to?(:call) || authorization_method.kind_of?(Symbol)
      raise Effective::AccessDenied.new() unless (controller || self).instance_exec(controller, action, resource, &authorization_method)
    end
    true
  end

  def self.supressed(&block)
    @supressed = true; yield; @supressed = false
  end

  def self.supressed?
    @supressed == true
  end

  def self.statuses
    @statuses ||= (
      Array(@@additional_statuses).map do |status|
        status.to_s.downcase
      end | ['info', 'success', 'error', log_changes_status, ('email' if email_enabled), ('sign_in' if sign_in_enabled), ('sign_out' if sign_out_enabled), 'view'].compact
    )
  end

  def self.log_changes_status
    'change'.freeze
  end

  # This is set by the "set_effective_logging_current_user" before_filter.
  def self.current_user=(user)
    @effective_logging_current_user = user
  end

  def self.current_user
    @effective_logging_current_user
  end

end
