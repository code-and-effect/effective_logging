unless Gem::Version.new(EffectiveDatatables::VERSION) < Gem::Version.new('3.0')
  class EffectiveLogsDatatable < Effective::Datatable
    datatable do
      order :updated_at

      col :updated_at, label: 'Date'
      col :id, visible: false

      if attributes[:user] == false
        # Do not include
      elsif attributes[:user_id].present?
        col :user, search: { collection: User.where(id: Array(attributes[:user_id])) }
      elsif attributes[:user].present?
        col :user, search: { collection: User.where(id: Array(attributes[:user]).map { |user| user.to_param }) }
      else
        col :user, search: { as: :string }
      end

      unless attributes[:status] == false
        col :status, search: { collection: EffectiveLogging.statuses }
      end

      unless attributes[:log_changes]
        col :associated
        #col :associated_type, search: { as: :string }, visible: false
        #col :associated_id, search: { as: :integer }, visible: false, label: 'Associated Id'
        #col :associated_to_s, search: { as: :string }, label: 'Associated'
      end

      col :message do |log|
        log.message.starts_with?("\t") ? log.message.gsub("\t", "&nbsp;&nbsp;") : log.message
      end

      col :logs_count, visible: false

      col :details, visible: false, sort: false do |log|
        tableize_hash(log.details.except(:email), th: true, sub_th: false, width: '100%')
      end

      actions_col partial: 'admin/logs/actions', partial_as: :log
    end

    # A nil attributes[:log_id] means give me all the top level log entries
    # If we set a log_id then it's for sub logs
    collection do
      scope = Effective::Log.unscoped.where(parent_id: attributes[:log_id]).includes(:user, :associated)

      if attributes[:log_changes]
        scope = scope.where(status: EffectiveLogging.log_changes_status)
      end

      if (attributes[:user] || attributes[:user_id]).present?
        user_ids = Array(attributes[:user].presence || attributes[:user_id]).map { |user| user.kind_of?(User) ? user.id : user.to_i }
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
end
