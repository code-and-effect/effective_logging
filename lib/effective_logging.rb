require 'effective_resources'
require 'effective_logging/engine'
require 'effective_logging/version'

module EffectiveLogging

  # The following are all valid config keys
  mattr_accessor :logs_table_name

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
    @_exceptions ||= [Effective::AccessDenied, (CanCan::AccessDenied if defined?(CanCan)), (Pundit::NotAuthorizedError if defined?(Pundit))].compact

    return !!authorization_method unless authorization_method.respond_to?(:call)
    controller = controller.controller if controller.respond_to?(:controller)

    begin
      !!(controller || self).instance_exec((controller || self), action, resource, &authorization_method)
    rescue *@_exceptions
      false
    end
  end

  def self.authorize!(controller, action, resource)
    raise Effective::AccessDenied unless authorized?(controller, action, resource)
  end

  def self.supressed(&block)
    @supressed = true; yield; @supressed = false
  end

  def self.supressed?
    @supressed == true
  end

  def self.statuses
    @statuses ||= (
      Array(@@additional_statuses).map { |status| status.to_s.downcase } |  # union
      ['info', 'success', 'error', 'view', log_changes_status, ('email' if email_enabled), ('sign_in' if sign_in_enabled), ('sign_out' if sign_out_enabled)].compact
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
