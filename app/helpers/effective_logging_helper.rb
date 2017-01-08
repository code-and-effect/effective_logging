module EffectiveLoggingHelper
  ALLOWED_TAGS = ActionView::Base.sanitized_allowed_tags.to_a + ['table', 'thead', 'tbody', 'tfoot', 'tr', 'td', 'th']
  ALLOWED_ATTRIBUTES = ActionView::Base.sanitized_allowed_attributes.to_a + ['colspan', 'rowspan']

  def bootstrap_class_for_status(status)
    case status
      when 'success'  ; 'success'
      when 'info'     ; 'info'
      when 'warning'  ; 'warning'
      when 'error'    ; 'danger'
      when 'trashed'  ; 'default'
      else 'primary'
    end
  end

  def render_log(log)
    render(partial: 'effective/logs/log', locals: {:log => log})
  end
  alias_method :render_trash, :render_log

  def parents_of_log(log)
    parents = [log.parent]
    parents << parents.last.parent while(parents.last.try(:parent_id).present?)
    parents.compact.reverse
  end

  # Call me with :th => true, :sub_th => false
  # Any other options are sent to the table tag
  def tableize_hash(hash, options = {})
    if hash.present? && hash.kind_of?(Hash)
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
                v.to_s
              end
            end
          end
        end.join('').html_safe
      end.html_safe
    else
      hash.to_s.html_safe
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

  def format_log_details_value(log, key)
    value = log.details[key]

    if value.kind_of?(Hash)
      tableize_hash(value, :class => 'table', :th => true)
    elsif value.kind_of?(Array)
      value.map { |value| effective_logging_simple_format(value) }.join.html_safe
    else
      value = value.to_s

      open = value.index('<!DOCTYPE html') || value.index('<html')
      close = value.rindex('</html>') if open.present?
      return effective_logging_simple_format(value) unless (open.present? && close.present?)

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

  def effective_logging_simple_format(value)
    simple_format(sanitize(value.to_s, :tags => ALLOWED_TAGS, :attributes => ALLOWED_ATTRIBUTES), {}, :sanitize => false)
  end


end
