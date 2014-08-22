if defined?(EffectiveDatatables)
  module Effective
    module Datatables
      class Logs < Effective::Datatable
        table_column :created_at do |log|
          log.created_at.strftime("%Y-%m-%d %H:%M:%S")
        end

        table_column :user_id, :filter => {:type => :select, :values => Proc.new { User.all.order(:email).map { |obj| [obj.id, obj.email] } }} do |log|
          log.user.try(:email)
        end

        table_column :status, :filter => {:type => :select, :values => EffectiveLogging.statuses }
        table_column :message

        table_column :actions, :sortable => false, :filter => false do |log|
          if log.logs_count.to_i > 0
            link_to "View (#{log.logs_count} more)", effective_logging.admin_log_path(log)
          else
            link_to 'View', effective_logging.admin_log_path(log)
          end
        end

        def collection
          Effective::Log.unscoped.where(:parent_id => nil).includes(:user)
        end

      end
    end
  end
end
