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

  # Log all page views
  config.page_views_enabled = false
  config.page_views = {
    :details => true,    # When true, will also collect params, request.referrer, request.remote_ip, request.format, request.user_agent
    :except => [:new, :create, :edit, :update, :destroy], # Only :index, :show and Non-RESTful actions will be logged
    :skip_namespace => [Admin]  # If the controller is in these namespaces, skip the logging
  }

end
