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

  def render_log(log)
    render(:partial => 'effective/logs/log', :locals => {:log => log})
  end

  def parents_of_log(log)
    parents = [log.parent]
    parents << parents.last.parent while(parents.last.try(:parent_id).present?)
    parents.compact.reverse
  end

  # Call me with :th => true, :sub_th => false
  # Any other options are sent to the table tag
  def tableize_hash(hash, options = {})
    if hash.present?
      content_tag(:table, options) do
        hash.map do |k, v|
          content_tag(:tr) do
            content_tag((options[:th] ? :th : :td), k) +
            content_tag(:td) do
              if v.kind_of?(Hash)
                tableize_hash(v, options.merge({:class => 'table table-bordered', :th => (options.key?(:sub_th) ? options[:sub_th] : options[:th])}))
              elsif v.kind_of?(Array)
                '[' + v.join(', ') + ']'
              else
                v
              end
            end
          end
        end.join('').html_safe
      end.html_safe
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
