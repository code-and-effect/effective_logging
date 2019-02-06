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

      if log.associated_type == attributes[:associated_type]
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
    base = Effective::Log.logged_changes.deep.where(parent_id: attributes[:log_id])
    scope = base.where(associated_type: attributes[:associated_type], associated_id: attributes[:associated_id])

    children_associations.each do |ass|
      next if ass.inverse_of.blank? || ass.inverse_of.foreign_key.blank?
      scope = scope.or(base.where(associated_type: ass.klass.name, associated_id: ass.klass.where(ass.inverse_of.foreign_key => attributes[:associated_id])))
    end

    scope
  end

  def children_associations
    @children_associations ||= Effective::Resource.new(attributes[:associated_type]).nested_resources.select { |ass| ass.klass.respond_to?(:acts_as_loggable?) }
  end

end
