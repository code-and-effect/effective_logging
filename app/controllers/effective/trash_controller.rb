module Effective
  class TrashController < ApplicationController
    if respond_to?(:before_action) # Devise
      before_action :authenticate_user!
    else
      before_filter :authenticate_user!
    end

    # This is the User index event
    def index
      @datatable = Effective::Datatables::Trash.new(user_id: current_user.id)
      @page_title = 'Trash'

      EffectiveLogging.authorized?(self, :restore, Effective::Log.new(user_id: current_user.id))
    end

    # This is the User show event
    def show
      @trash = Effective::Log.trash.find(params[:id])
      @page_title = "Trash #{@trash.to_s}"

      EffectiveLogging.authorized?(self, :restore, @trash)
    end

    def restore
      @trash = Effective::Log.trash.find(params[:id])
      EffectiveLogging.authorized?(self, :restore, @trash)

      Effective::Log.transaction do
        begin
          @trash.restore_trashable!
          @trash.destroy!
          flash[:success] = "Successfully restored #{@trash}"
        rescue => e
          flash[:danger] = "Unable to restore: #{e.message}"
          raise ActiveRecord::Rollback
        end
      end

      redirect_back(fallback_location: effective_logging.trash_path)
    end

  end
end
