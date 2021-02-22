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

  end
end
