module Admin
  class TracksController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_logging) }

    include Effective::CrudController
  end
end
