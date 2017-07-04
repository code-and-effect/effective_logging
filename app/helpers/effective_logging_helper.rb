module EffectiveLoggingHelper

  def bootstrap_class_for_status(status)
    case status
      when 'success'  ; 'success'
      when 'info'     ; 'info'
      when 'warning'  ; 'warning'
      when 'error'    ; 'danger'
      when 'change'   ; 'info'
      else 'primary'
    end
  end

  def render_log(log)
    render(partial: 'effective/logs/log', locals: {log: log})
  end

  def parents_of_log(log)
    parents = [log.parent]
    parents << parents.last.parent while(parents.last.try(:parent_id).present?)
    parents.compact.reverse
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

  # tabelize_hash and format_resource_value are from effective_resources
  def format_log_details_value(log, key)
    value = log.details[key]

    return tableize_hash(value) unless value.kind_of?(String)

    open = value.index('<!DOCTYPE html') || value.index('<html')
    close = value.rindex('</html>') if open.present?
    return format_resource_value(value) unless (open.present? && close.present?)

    before = value[0...open]
    after = value[(close+7)..-1]
    divide = before.sub!('<hr>', '').present?

    [
      h(before).gsub("\n", '<br>'),
      (content_tag(:hr) if divide),
      content_tag(:iframe, '',
        src: effective_logging.html_part_log_path(log, key: key),
        style: 'frameborder: 0; border: 0; width: 100%; height: 100%;',
        onload: "this.style.height=(this.contentDocument.body.scrollHeight + 30) + 'px';",
        scrolling: 'no'),
      h(after).gsub("\n", '<br>')
    ].compact.join.html_safe
  end

end
