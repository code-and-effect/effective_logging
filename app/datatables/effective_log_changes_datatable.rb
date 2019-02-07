class EffectiveLogChangesDatatable < Effective::Datatable
  datatable do
    order :updated_at

    col :updated_at, label: 'Date'
    col :id, visible: false

    col :user, sort: false

    col :associated_type, visible: false
    col :associated_id, visible: false
    col :associated_to_s, visible: false

    col :message, sort: false do |log|
      message = log.message.gsub("\n", '<br>')

      if log.associated_id == attributes[:changes_to_id] && log.associated_type == attributes[:changes_to_type]
        message
      else
        "#{log.associated_type} #{log.associated_to_s} - #{message}"
      end

    end.search do |collection, term, column, sql_column|
      collection.where("associated_type #{resource.ilike} ? OR associated_to_s #{resource.ilike} ? OR message #{resource.ilike} ?", "%#{term}%", "%#{term}%", "%#{term}%")
    end

    col :details, visible: false, sort: false do |log|
      tableize_hash(log.details)
    end

    unless attributes[:actions] == false
      actions_col partial: 'admin/logs/actions', partial_as: :log
    end
  end

  # A nil attributes[:log_id] means give me all the top level log entries
  # If we set a log_id then it's for sub logs
  collection do
    Effective::Log.logged_changes.deep
      .where(changes_to_type: attributes[:changes_to_type], changes_to_id: attributes[:changes_to_id])
  end

end
