if defined?(EffectiveDatatables)
  module Effective
    module Datatables
      class Logs < Effective::Datatable
        include EffectiveLoggingHelper

        default_order :created_at, :desc

        table_column :created_at

        table_column :id, visible: false

        table_column :parent_id, visible: false
        table_column :user, :if => proc { attributes[:user_id].blank? }

        table_column :status, filter: { type: :select, values: EffectiveLogging.statuses }

        table_column :message, width: '50%', sortable: false
        table_column :logs_count, visible: false

        table_column :details, visible: false, sortable: false do |log|
          log.details.delete(:email)
          tableize_hash(log.details, th: true, sub_th: false, width: '100%')
        end

        table_column :read_at, visible: false
        table_column :updated_at, visible: false

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
          if attributes[:user_id].present?
            Effective::Log.unscoped.where(:parent_id => attributes[:log_id]).where(:user_id => attributes[:user_id]).includes(:user)
          else
            Effective::Log.unscoped.where(:parent_id => attributes[:log_id]).includes(:user)
          end
        end

      end
    end
  end
end
