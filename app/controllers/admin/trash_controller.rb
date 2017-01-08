# This copies the permissions of The Logs controller

module Admin
  class TrashController < ApplicationController
    respond_to?(:before_action) ? before_action(:authenticate_user!) : before_filter(:authenticate_user!) # Devise

    layout (EffectiveLogging.layout.kind_of?(Hash) ? EffectiveLogging.layout[:admin_trash] : EffectiveLogging.layout)

    skip_log_page_views quiet: true
    helper EffectiveLoggingHelper

    def index
      @datatable = Effective::Datatables::Trash.new()
      @page_title = 'Trash'

      EffectiveLogging.authorized?(self, :restore, Effective::Log)
      EffectiveLogging.authorized?(self, :admin, :effective_logging)
    end

    def show
      @trash = Effective::Log.trash.find(params[:id])
      @page_title = "Trash #{@trash.to_s}"

      EffectiveLogging.authorized?(self, :restore, @trash)
      EffectiveLogging.authorized?(self, :admin, :effective_logging)
    end
  end
end
