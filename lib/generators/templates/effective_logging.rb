EffectiveLogging.setup do |config|
  # Configure Database Tables
  config.logs_table_name = :logs

  # Authorization Method - Can this user view the Admin screen?
  config.authorization_method = Proc.new { |controller, action, resource| can?(action, resource) } # CanCan gem

  # Admin Screen Layout Settings
  # Configure the Layout per controller, or all at once
  config.layout = 'application'   # All EffectiveLogging controllers will use this layout
  #config.layout = { :admin_logs => 'application'}

  # All statuses defined here, as well as 'info', 'success', and 'error' (hardcoded) will be created as
  # EffectiveLogger.info 'my message' macros
  config.additional_statuses = []

  #########################################
  #### Automatic Logging Functionality ####
  #########################################

  # Log all emails sent
  config.emails_enabled = true

  # Log all successful user login attempts
  config.user_logins_enabled = true

  ### You also have to manually add this to ApplicationController
  # log_page_views :skip_namespace => [Admin], :details => true, :except => [:new, :create, :edit, :update, :destroy]
  # and then you can use
  # skip_log_page_views in additional controllers

end
