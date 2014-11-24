if defined?(EffectiveDatatables)
  module Effective
    module Datatables
      class Logs < Effective::Datatable
        include EffectiveLoggingHelper

        default_order :created_at, :desc

        table_column :created_at

        table_column :user_id, :if => Proc.new { attributes[:user_id].blank? }, :filter => {:type => :select, :values => Proc.new { User.all.order(:email).map { |obj| [obj.id, obj.email] } }} do |log|
          log.user.try(:email)
        end

        table_column :status, :filter => {:type => :select, :values => EffectiveLogging.statuses }
        table_column :message, :width => '50%'

        table_column :details, :visible => false do |log|
          log.details.delete(:email)
          tableize_hash(log.details, :th => true, :sub_th => false, :width => '100%')
        end

        table_column :actions, :sortable => false, :filter => false do |log|
          show_path = (attributes[:active_admin] ? admin_effective_log_path(log) : effective_logging.admin_log_path(log))

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
