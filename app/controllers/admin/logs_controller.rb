module Admin
  class LogsController < ApplicationController
    respond_to?(:before_action) ? before_action(:authenticate_user!) : before_filter(:authenticate_user!) # Devise

    layout (EffectiveLogging.layout.kind_of?(Hash) ? EffectiveLogging.layout[:admin_logs] : EffectiveLogging.layout)

    skip_log_page_views quiet: true
    helper EffectiveLoggingHelper

    def index
      if Gem::Version.new(EffectiveDatatables::VERSION) < Gem::Version.new('3.0')
        @datatable = Effective::Datatables::Logs.new()
      else
        @datatable = EffectiveLogsDatatable.new(self)
      end

      @page_title = 'Logs'

      EffectiveLogging.authorized?(self, :index, Effective::Log)
      EffectiveLogging.authorized?(self, :admin, :effective_logging)
    end

    def show
      @log = Effective::Log.includes(:logs).find(params[:id])
      @log.next_log = Effective::Log.unscoped.order(:id).where(parent_id: @log.parent_id).where('id > ?', @log.id).first
      @log.prev_log = Effective::Log.unscoped.order(:id).where(parent_id: @log.parent_id).where('id < ?', @log.id).last

      @page_title = "Log ##{@log.to_param}"

      if @log.logs.present?
        if Gem::Version.new(EffectiveDatatables::VERSION) < Gem::Version.new('3.0')
          @log.datatable = Effective::Datatables::Logs.new(log_id: @log.id)
        else
          @log.datatable = EffectiveLogsDatatable.new(self, log_id: @log.id)
        end
      end

      EffectiveLogging.authorized?(self, :show, @log)
      EffectiveLogging.authorized?(self, :admin, :effective_logging)
    end
  end
end
