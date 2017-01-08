if defined?(EffectiveDatatables)
  module Effective
    module Datatables
      class Trash < Effective::Datatable
        include EffectiveLoggingHelper

        datatable do
          default_order :created_at, :desc

          table_column :created_at, label: 'Destroyed at'
          table_column :id, visible: false

          unless attributes[:user_id] || attributes[:user] || (attributes[:user] == false)
            table_column :user, label: 'Destroyed by', visible: false
          end

          table_column :associated_type, label: 'Type'
          table_column :associated_id, label: 'Original Id', visible: false
          table_column :message, label: 'Item'

          table_column :details, visible: true, sortable: false do |trash|
            tableize_hash(trash.details.except(:trash), th: true, sub_th: false, width: '100%')
          end

          unless attributes[:actions] == false
            actions_column partial: 'admin/trash/actions', partial_local: :trash
          end
        end

        # A nil attributes[:log_id] means give me all the top level log entries
        # If we set a log_id then it's for sub logs
        def collection
          collection = Effective::Log.trash.includes(:user)

          if attributes[:user_id].present?
            collection = collection.where(user_id: attributes[:user_id])
          end

          if attributes[:user].present?
            collection = collection.where(user: attributes[:user])
          end

          if attributes[:associated_id] && attributes[:associated_type]
            collection = collection.where(associated_id: attributes[:associated_id], associated_type: attributes[:associated_type])
          end

          collection
        end

      end
    end
  end
end
