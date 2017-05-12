if Gem::Version.new(EffectiveDatatables::VERSION) < Gem::Version.new('3.0')
  module Effective
    module Datatables
      class Logs < Effective::Datatable
        include EffectiveLoggingHelper

        datatable do
          default_order :updated_at, :desc

          table_column :updated_at, label: 'Date'
          table_column :id, visible: false

          if attributes[:user] == false
            # Do not include
          elsif attributes[:user_id].present?
            table_column :user, filter: { collection: User.where(id: Array(attributes[:user_id])) }
          elsif attributes[:user].present?
            table_column :user, filter: { collection: User.where(id: Array(attributes[:user]).map { |user| user.to_param }) }
          else
            table_column :user
          end

          unless attributes[:status] == false
            table_column :status, filter: { type: :select, values: EffectiveLogging.statuses }
          end

          unless attributes[:log_changes]
            table_column :associated_type, visible: false
            table_column :associated_id, visible: false, label: 'Associated Id'
            table_column :associated_to_s, label: 'Associated'
          end

          if attributes[:log_changes]
            table_column :message do |log|
              log.message.starts_with?("\t") ? log.message.gsub("\t", "&nbsp;&nbsp;") : log.message
            end
          else
            table_column :message
          end

          table_column :logs_count, visible: false

          table_column :details, visible: false, sortable: false do |log|
            tableize_hash(log.details.except(:email), th: true, sub_th: false, width: '100%')
          end

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
            user_ids = Array(attributes[:user].presence || attributes[:user_id]).map { |user| user.kind_of?(User) ? user.id : user.to_i }
            collection = collection.where('user_id IN (?) OR (associated_id IN (?) AND associated_type = ?)', user_ids, user_ids, 'User')
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
