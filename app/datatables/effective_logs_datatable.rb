class EffectiveLogsDatatable < Effective::Datatable
  datatable do
    order :updated_at

    col :updated_at, label: 'Date'
    col :id, visible: false

    if attributes[:user] == false
      # Do not include
    elsif attributes[:for]
      col :user, search: :string
    else
      col :user
    end

    unless attributes[:status] == false
      col :status, search: { collection: EffectiveLogging.statuses }
    end

    unless attributes[:log_changes]
      col :associated_type, search: { as: :string }, visible: false
      col :associated_id, search: { as: :integer }, visible: false, label: 'Associated Id'
      col :associated_to_s, search: { as: :string }, label: 'Associated'
    end

    if attributes[:log_changes]
      col :message do |log|
        log.message.starts_with?("\t") ? log.message.gsub("\t", "&nbsp;&nbsp;") : log.message
      end
    else
      col :message
    end

    col :logs_count, visible: false

    col :details, visible: false, sort: false do |log|
      tableize_hash(log.details.except(:email))
    end

    unless attributes[:actions] == false
      actions_col partial: 'admin/logs/actions', partial_as: :log
    end
  end

  # A nil attributes[:log_id] means give me all the top level log entries
  # If we set a log_id then it's for sub logs
  collection do
    scope = Effective::Log.deep.where(parent_id: attributes[:log_id])

    if attributes[:log_changes]
      scope = scope.where(status: EffectiveLogging.log_changes_status)
    end

    if attributes[:for]
      user_ids = Array(attributes[:for])
      scope = scope.where('user_id IN (?) OR (associated_id IN (?) AND associated_type = ?)', user_ids, user_ids, 'User')
    end

    if attributes[:associated_id] && attributes[:associated_type]
      scope = scope.where(associated_id: attributes[:associated_id], associated_type: attributes[:associated_type])
    end

    if attributes[:associated]
      scope = scope.where(associated: attributes[:associated])
    end

    scope
  end

end
