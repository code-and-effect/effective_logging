EffectiveLogging.setup do |config|
  # Configure Database Tables
  config.logs_table_name = :logs

  # Authorization Method - Can this user view the Admin screen?
  config.authorization_method = Proc.new { |controller, action, resource| can?(action, resource) } # CanCan gem

  # Layout Settings
  # Configure the Layout per controller, or all at once

  # config.layout = 'application'   # All EffectiveLogging controllers will use this layout

  config.layout = {
    :admin_logs => 'application'
  }

  # All statuses defined here, as well as 'info', 'success', and 'error' (hardcoded) will be created as
  # Log.info 'my message' macros
  config.statuses = []
end
