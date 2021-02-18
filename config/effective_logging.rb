EffectiveLogging.setup do |config|
  # Configure Database Tables
  config.logs_table_name = :logs

  # Admin Screens Layout Settings
  # config.layout = { application: 'application', admin: 'admin' }

  # EffectiveLogger.info('my message') macros
  # The following exist: info, success, error, view, change, download, email, sign_in, sign_out
  # Add more here
  config.additional_statuses = []

  #########################################
  #### Automatic Logging Functionality ####
  #########################################

  # Log all active storage downloads
  config.active_storage_enabled = true

  # Log all sent emails
  config.email_enabled = true

  # Log all sign ins (successful only)
  config.sign_in_enabled = true

  # Log all sign outs
  config.sign_out_enabled = false
end
