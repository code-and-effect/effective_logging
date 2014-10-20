if defined?(ActiveAdmin)

  ActiveAdmin.register Effective::Log do
    menu :label => 'Logs', :if => proc { EffectiveLogging.authorized?(controller, :manage, Effective::Log.new()) rescue false }

    actions :index, :show

    config.filters = false
    config.paginate = false

    controller do
      def index
        @datatable = Effective::Datatables::Logs.new(:active_admin => true)

        @_effective_logging_active_admin = true
        render :file => 'active_admin/effective_logging/logs/index', :layout => 'active_admin'
      end

      def show
        @log = Effective::Log.includes(:logs).find(params[:id])

        if @log.logs.present?
          @datatable = Effective::Datatables::Logs.new(:log_id => @log.id, :active_admin => true)
        end

        @_effective_logging_active_admin = true
        render :file => 'active_admin/effective_logging/logs/show', :layout => 'active_admin'
      end
    end
  end

end
