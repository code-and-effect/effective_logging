# frozen_string_literal: true

class EffectiveLogChangesDatatable < Effective::Datatable
  datatable do
    order :id, :desc

    col :updated_at, label: 'Date'
    col :id, visible: false

    col :user, search: :string, sort: false

    col :associated_type, visible: false
    col :associated_id, visible: false, label: 'Associated Id'
    col :associated_to_s, visible: false, label: 'Associated'

    col :message, sort: false do |log|
      message = (log.message || '').gsub("\n", '<br>')

      if log.associated_id == attributes[:changes_to_id] && log.associated_type == attributes[:changes_to_type]
        message
      else
        "#{log.associated_type} #{log.associated_to_s} - #{message}"
      end

    end.search do |collection, term, column, sql_column|
      ilike = effective_resource.ilike
      collection.where("associated_type #{ilike} ? OR associated_to_s #{ilike} ? OR message #{ilike} ?", "%#{term}%", "%#{term}%", "%#{term}%")
    end

    col :details, visible: false, sort: false do |log|
      tableize_hash(log.details)
    end

    actions_col
  end

  # A nil attributes[:log_id] means give me all the top level log entries
  # If we set a log_id then it's for sub logs
  collection do
    Effective::Log.logged_changes.deep
      .where(changes_to_type: attributes[:changes_to_type], changes_to_id: attributes[:changes_to_id])
  end

end
