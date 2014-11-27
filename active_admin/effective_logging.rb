if defined?(ActiveAdmin)

  ActiveAdmin.register Effective::Log do
    menu :label => 'Logs', :if => proc { EffectiveLogging.authorized?(controller, :manage, Effective::Log.new()) rescue false }

    actions :index, :show

    config.filters = false
    config.paginate = false

    controller do
      def index
        @datatable = Effective::Datatables::Logs.new(:active_admin => true) if defined?(EffectiveDatatables)
        render :file => 'active_admin/effective_logging/logs/index', :layout => 'active_admin'
      end

      def show
        @log = Effective::Log.includes(:logs).find(params[:id])
        @log.next_log = Effective::Log.unscoped.order(:id).where(:parent_id => @log.parent_id).where('id > ?', @log.id).first
        @log.prev_log = Effective::Log.unscoped.order(:id).where(:parent_id => @log.parent_id).where('id < ?', @log.id).last

        if @log.logs.present?
          @log.datatable = Effective::Datatables::Logs.new(:log_id => @log.id, :active_admin => true) if defined?(EffectiveDatatables)
        end

        render :file => 'active_admin/effective_logging/logs/show', :layout => 'active_admin'
      end
    end
  end

end
