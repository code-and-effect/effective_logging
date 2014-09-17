module Effective
  class LogsController < ApplicationController
    skip_log_page_views

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
