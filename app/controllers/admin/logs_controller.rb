module Admin
  class LogsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_logging) }

    include Effective::CrudController
    skip_log_page_views

    if (config = EffectiveLogging.layout)
      layout(config.kind_of?(Hash) ? config[:admin] : config)
    end

  end
end
