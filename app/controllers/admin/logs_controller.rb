module Admin
  class LogsController < ApplicationController
    before_filter :authenticate_user!   # This is devise, ensure we're logged in.

    layout (EffectiveLogging.layout.kind_of?(Hash) ? EffectiveLogging.layout[:admin_logs] : EffectiveLogging.layout)

    def index
      @datatable = Effective::Datatables::Logs.new() if defined?(EffectiveDatatables)
      @page_title = 'Logs'

      EffectiveLogging.authorized?(self, :index, Effective::Log)
    end

    def show
      @log = Effective::Log.includes(:logs).find(params[:id])
      @page_title = "Log ##{@log.to_param}"

      if @log.logs.present?
        @datatable = Effective::Datatables::Logs.new(:log_id => @log.id) if defined?(EffectiveDatatables)
      end

      EffectiveLogging.authorized?(self, :show, @log)
    end
  end
end
