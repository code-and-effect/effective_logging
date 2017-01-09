module Effective
  class LogsController < ApplicationController
    skip_log_page_views quiet: true

    if respond_to?(:before_action) # Devise
      before_action :authenticate_user!, only: [:index, :show]
    else
      before_filter :authenticate_user!, only: [:index, :show]
    end

    # This is a post from our Javascript
    def create
      EffectiveLogging.authorized?(self, :create, Effective::Log.new())

      @log = Effective::Log.new().tap do |log|
        log.message = log_params[:message]
        log.status = (EffectiveLogging.statuses.include?(log_params[:status]) ? log_params[:status] : 'info')
        log.user = (current_user rescue nil)

        #log.parent = options.delete(:parent)
        #log.associated = options.delete(:associated)

        count = -1
        Array((JSON.parse(log_params[:details]) rescue [])).flatten(1).each do |obj|
          if obj.kind_of?(Hash)
            obj.each { |k, v| log.details[k] = v if v.present? }
          else
            log.details["param_#{(count += 1)}"] = obj if obj.present?
          end
        end

        log.details[:referrer] = request.referrer

        log.save
      end

      render :text => "ok", :status => :ok
    end

    # This is the User index event
    def index
      @datatable = Effective::Datatables::Logs.new(:user_id => current_user.id)
      @page_title = 'My Activity'

      EffectiveLogging.authorized?(self, :index, Effective::Log.new(:user_id => current_user.id))
    end

    # This is the User show event
    def show
      @log = Effective::Log.includes(:logs).find(params[:id])
      @log.next_log = Effective::Log.unscoped.order(:id).where(parent_id: @log.parent_id).where('id > ?', @log.id).first
      @log.prev_log = Effective::Log.unscoped.order(:id).where(parent_id: @log.parent_id).where('id < ?', @log.id).last

      @page_title = "Log ##{@log.to_param}"

      if @log.logs.present?
        @log.datatable = Effective::Datatables::Logs.new(log_id: @log.id) if defined?(EffectiveDatatables)
      end

      EffectiveLogging.authorized?(self, :show, @log)
    end

    def html_part
      @log = Effective::Log.find(params[:id])

      EffectiveLogging.authorized?(self, :show, @log)

      value = @log.details[(params[:key] || '').to_sym].to_s

      open = value.index('<!DOCTYPE html') || value.index('<html')
      close = value.rindex('</html>') if open.present?

      if open.present? && close.present?
        render text: value[open...(close+7)]
      else
        render text: value
      end
    end

    private

    # StrongParameters
    def log_params
      begin
        params.require(:effective_log).permit(:message, :status, :details)
      rescue => e
        params[:effective_log] || {}
      end
    end

  end
end
