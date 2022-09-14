class EffectiveLogsDatatable < Effective::Datatable
  datatable do
    order :id, :desc

    col :updated_at, label: 'Date'
    col :id, visible: false

    if attributes[:user] == false
      # Do not include
    else
      col :user, search: :string, sort: false
    end

    unless attributes[:status] == false
      col :status, search: { collection: EffectiveLogging.statuses }
    end

    col :changes_to_type, visible: false
    col :changes_to_id, visible: false

    col :associated_type, visible: false
    col :associated_id, visible: false, label: 'Associated Id'
    col :associated_to_s, label: 'Associated'

    col :message do |log|
      (log.message || '').gsub("\n", '<br>')
    end

    col :logs_count, visible: false

    col :details, visible: false, sort: false do |log|
      tableize_hash(log.details.except(:email))
    end

    actions_col
  end

  # A nil attributes[:log_id] means give me all the top level log entries
  # If we set a log_id then it's for sub logs
  collection do
    scope = Effective::Log.includes(:user).where(parent_id: attributes[:log_id])

    # Older syntax, pass by integer
    if attributes[:for]
      user_ids = Array(attributes[:for])
      scope = scope.where('user_id IN (?) OR (associated_id IN (?) AND associated_type = ?)', user_ids, user_ids, 'User')
    end

    # Newer syntax, pass by object
    if attributes[:for_id] && attributes[:for_type]
      for_scope = scope.where(associated_id: attributes[:for_id], associated_type: attributes[:for_type])
        .or(scope.where(changes_to_id: attributes[:for_id], changes_to_type: attributes[:for_type]))
        .or(scope.where(user_id: attributes[:for_id], user_type: attributes[:for_type]))
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
