module Admin
  class LogsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_logging) }

    include Effective::CrudController
    skip_log_page_views

    if (config = EffectiveLogging.layout)
      layout(config.kind_of?(Hash) ? config[:admin] : config)
    end

    def index
      EffectiveResources.authorize!(self, :index, Effective::Log)
      @datatable = EffectiveLogsDatatable.new(self)
      @page_title = 'Logs'
    end

    def show
      @log = Effective::Log.includes(:logs).find(params[:id])
      EffectiveLogging.authorize!(self, :show, @log)

      @log.next_log = Effective::Log.order(:id).where(parent_id: @log.parent_id).where('id > ?', @log.id).first
      @log.prev_log = Effective::Log.order(:id).where(parent_id: @log.parent_id).where('id < ?', @log.id).last

      @page_title = "Log ##{@log.to_param}"

      if @log.logs.present?
        @log.datatable = EffectiveLogsDatatable.new(self, log_id: @log.id)
      end

    end
  end
end
