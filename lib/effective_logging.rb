require 'effective_resources'
require 'effective_logging/engine'
require 'effective_logging/version'

module EffectiveLogging
  def self.config_keys
    [
      :logs_table_name, :tracks_table_name, :layout, :additional_statuses,
      :log_class_name,
      :active_storage_enabled, :active_storage_only, :active_storage_except, 
      :email_enabled, :sign_in_enabled, :sign_out_enabled
    ]
  end

  include EffectiveGem

  def self.Log
    log_class_name&.constantize || Effective::Log
  end

  def self.statuses
    @statuses ||= (
      base = [
        'info',
        'success',
        'error',
        'view',
        log_changes_status, # 'change'
        ('download' if active_storage_enabled),
        ('email' if email_enabled),
        ('sign_in' if sign_in_enabled),
        ('sign_out' if sign_out_enabled)
      ].compact

      additional = Array(additional_statuses).map { |status| status.to_s.downcase }

      base | additional # union
    )
  end

  def self.log_changes_status
    'change'.freeze
  end

  # This is set by the "set_effective_logging_current_user" before_filter.
  def self.current_user=(user)
    Thread.current[:effective_logging_current_user] = user
  end

  def self.current_user
    Thread.current[:effective_logging_current_user]
  end

  # Used to supress all logging
  def self.supressed=(value)
    Thread.current[:effective_logging_supressed] = value
  end

  def self.supressed(&block)
    Thread.current[:effective_logging_supressed] = true
    value = yield
    Thread.current[:effective_logging_supressed] = nil
    value
  end

  def self.supressed?
    Thread.current[:effective_logging_supressed] == true
  end

  # For ActiveStorageLogger
  def self.active_storage_onlies
    onlies = Array(active_storage_only) - [nil, '', ' ']
    raise("effective_logging.active_storage_only should be an Array of Strings") if onlies.present? && !onlies.all? { |type| type.kind_of?(String) }
    onlies
  end

  def self.active_storage_excepts
    excepts = Array(active_storage_except) - [nil, '', ' ']
    raise("effective_logging.active_storage_except should be an Array of Strings") if excepts.present? && !excepts.all? { |type| type.kind_of?(String) }
    excepts
  end

end
