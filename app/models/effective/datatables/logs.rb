if defined?(EffectiveDatatables)
  module Effective
    module Datatables
      class Logs < Effective::Datatable
        include EffectiveLoggingHelper

        datatable do
          default_order :created_at, :desc

          table_column :created_at
          table_column :id, visible: false

          unless attributes[:user_id] || attributes[:user] || (attributes[:user] == false)
            table_column :user
          end

          unless attributes[:status] == false
            table_column :status, filter: { type: :select, values: (EffectiveLogging.statuses + [EffectiveLogging.log_changes_status]) }
          end

          table_column :associated_type, visible: false
          table_column :associated_id, visible: false, label: 'Associated Id'
          table_column :associated_to_s, label: 'Associated'

          table_column :message do |log|
            log.message.starts_with?("\t") ? log.message.gsub("\t", "&nbsp;&nbsp;") : log.message
          end

          table_column :logs_count, visible: false

          table_column :details, visible: false, sortable: false do |log|
            tableize_hash(log.details.except(:email), th: true, sub_th: false, width: '100%')
          end

          table_column :updated_at, visible: false

          unless attributes[:actions] == false
            actions_column partial: 'admin/logs/actions', partial_local: :log
          end
        end

        # A nil attributes[:log_id] means give me all the top level log entries
        # If we set a log_id then it's for sub logs
        def collection
          collection = Effective::Log.unscoped.where(parent_id: attributes[:log_id]).includes(:user, :associated)

          if attributes[:log_changes]
            collection = collection.where(status: EffectiveLogging.log_changes_status)
          end

          if (attributes[:user] || attributes[:user_id]).present?
            user_id = attributes[:user_id] || (attributes[:user].kind_of?(User) ? attributes[:user].id : attributes[:user].to_i)
            collection = collection.where('user_id = ? OR (associated_id = ? AND associated_type = ?)', user_id, user_id, 'User')
          end

          if attributes[:associated_id] && attributes[:associated_type]
            collection = collection.where(associated_id: attributes[:associated_id], associated_type: attributes[:associated_type])
          end

          if attributes[:associated]
            collection = collection.where(associated: attributes[:associated])
          end

          collection
        end

      end
    end
  end
end
