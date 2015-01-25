if defined?(EffectiveDatatables)
  module Effective
    module Datatables
      class Logs < Effective::Datatable
        include EffectiveLoggingHelper

        USER_COLUMN_SQL = <<-SQL
          CASE WHEN users.first_name IS NULL OR users.last_name IS NULL THEN users.email ELSE (users.first_name || ' ' || users.last_name) END
        SQL

        default_order :created_at, :desc

        table_column(:created_at) { |log| log.created_at.strftime('%Y-%m-%d %H:%M') }

        table_column :id, visible: false

        table_column :parent_id, visible: false
        table_column(:user, type: :string, column: USER_COLUMN_SQL) do |log|
          link_to(log.user_name, edit_admin_user_path(log.user_id)) rescue log.user_name
        end

        table_column :associated_id, visible: false
        table_column :associated_type, visible: false

        table_column :status, filter: { type: :select, values: EffectiveLogging.statuses }

        table_column :message, width: '50%', sortable: false
        table_column :logs_count, visible: false

        table_column :details, visible: false, sortable: false do |log|
          log.details.delete(:email)
          tableize_hash(log.details, th: true, sub_th: false, width: '100%')
        end

        table_column(:updated_at, visible: false) { |log| log.updated_at.strftime('%Y-%m-%d %H:%M') }

        table_column :actions, sortable: false, filter: false do |log|
          show_path =
            if datatables_active_admin_path?
              admin_effective_log_path(log)
            elsif datatables_admin_path?
              effective_logging.admin_log_path(log)
            else
              effective_logging.log_path(log)
            end

          if log.logs_count.to_i > 0
            link_to "View&nbsp;(#{log.logs_count}&nbsp;more)".html_safe, show_path
          else
            link_to 'View', show_path
          end
        end

        # A nil attributes[:log_id] means give me all the top level log entries
        # If we set a log_id then it's for sub logs
        def collection
          col = Effective::Log.unscoped
            .where(parent_id: attributes[:log_id])
            .joins('LEFT JOIN users ON users.id = logs.user_id')
            .select("logs.*, #{ USER_COLUMN_SQL } AS user_name")

          attributes[:user_id].present? ? col.where(user_id: attributes[:user_id]) : col
        end

        def search_column(collection, table_column, search_term)
          return collection.where('logs.logs_count >= ?', search_term.to_i) if table_column[:name] == 'logs_count'
          super
        end
      end
    end
  end
end
