module Admin
  class LogsController < ApplicationController
    before_action :authenticate_user!
    skip_log_page_views

    layout (EffectiveLogging.layout.kind_of?(Hash) ? EffectiveLogging.layout[:admin_logs] : EffectiveLogging.layout)

    def index
      @datatable = EffectiveLogsDatatable.new(self)

      @page_title = 'Logs'

      EffectiveLogging.authorize!(self, :index, Effective::Log)
      EffectiveLogging.authorize!(self, :admin, :effective_logging)
    end

    def show
      @log = Effective::Log.includes(:logs).find(params[:id])
      @log.next_log = Effective::Log.order(:id).where(parent_id: @log.parent_id).where('id > ?', @log.id).first
      @log.prev_log = Effective::Log.order(:id).where(parent_id: @log.parent_id).where('id < ?', @log.id).last

      @page_title = "Log ##{@log.to_param}"

      if @log.logs.present?
        @log.datatable = EffectiveLogsDatatable.new(self, log_id: @log.id)
      end

      EffectiveLogging.authorize!(self, :show, @log)
      EffectiveLogging.authorize!(self, :admin, :effective_logging)
    end
  end
end
