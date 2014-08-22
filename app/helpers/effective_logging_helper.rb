module EffectiveLoggingHelper
  def bootstrap_class_for_status(status)
    case status
      when 'success'  ; 'success'
      when 'info'     ; 'info'
      when 'warning'  ; 'warning'
      when 'error'    ; 'danger'
      else 'primary'
    end
  end

  # This is called on the Logs#show Admin page, and is intended for override by the application
  def effective_logging_object_link_to(obj, action = :show)
    if obj.kind_of?(User)
      return (
        if action == :show && defined?(admin_user_path)
          link_to('View', admin_user_path(obj))
        elsif action == :edit && defined?(edit_admin_user_path)
          link_to('Edit', edit_admin_user_path(obj))
        end
      )
    end
  end


end
