module Effective
  class LogsController < ApplicationController
    before_action(:authenticate_user!, only: [:index, :show]) if defined?(Devise)

    include Effective::CrudController
    skip_log_page_views

    if (config = EffectiveLogging.layout)
      layout(config.kind_of?(Hash) ? config[:application] : config)
    end

    # This is a post from our Javascript
    def create
      EffectiveResources.authorize!(self, :create, Effective::Log.new)

      @log = Effective::Log.new.tap do |log|
        log.message = log_params[:message]
        log.status = EffectiveLogging.statuses.find { |status| status == log_params[:status] } || 'info'
        log.user = EffectiveLogging.current_user || current_user

        count = -1
        Array((JSON.parse(log_params[:details]) rescue [])).flatten(1).each do |obj|
          if obj.kind_of?(Hash)
            obj.each { |k, v| log.details[k] = v if v.present? }
          else
            log.details["param_#{(count += 1)}"] = obj if obj.present?
          end
        end

        # Match the referrer
        log.details[:ip] ||= request.ip
        log.details[:referrer] ||= request.referrer
        log.details[:user_agent] ||= request.user_agent

        log.save
      end

      render text: 'ok', status: :ok, json: {}
    end

    # This is the User index event
    def index
      EffectiveResources.authorize!(self, :index, Effective::Log.new(user_id: current_user.id))
      @datatable = EffectiveLogsDatatable.new(self, for: current_user.id)
    end

    def html_part
      @log = Effective::Log.find(params[:id])

      EffectiveResources.authorize!(self, :show, @log)

      value = @log.details[(params[:key] || '').to_sym].to_s

      open = value.index('<!DOCTYPE html') || value.index('<html')
      close = value.rindex('</html>') if open.present?

      if open.present? && close.present?
        render inline: value[open...(close+7)].html_safe
      else
        render inline: value.html_safe
      end
    end

    private

    # StrongParameters
    def log_params
      params.require(:effective_log).permit(:message, :status, :details)
    end

  end
end
