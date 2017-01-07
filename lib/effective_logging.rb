require 'haml-rails'
require 'effective_logging/engine'
require 'effective_logging/version'

module EffectiveLogging

  # The following are all valid config keys
  mattr_accessor :logs_table_name
  mattr_accessor :use_active_admin

  mattr_accessor :authorization_method
  mattr_accessor :layout
  mattr_accessor :additional_statuses

  mattr_accessor :emails_enabled
  mattr_accessor :user_logins_enabled
  mattr_accessor :user_logouts_enabled

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
    @statuses ||= (Array(@@additional_statuses).map { |status| status.to_s.downcase } | ['info', 'success', 'error'])
  end

  def self.log_changes_status
    'logged change'.freeze
  end

  def self.trashable_status
    'trashed'.freeze
  end

  # This is set by the "set_log_changes_user" before_filter.
  def self.log_changes_user=(user)
    @log_changes_user = user
  end

  def self.log_changes_user
    @log_changes_user
  end

end
