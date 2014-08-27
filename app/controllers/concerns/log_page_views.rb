module LogPageViews
  extend ActiveSupport::Concern

  module ActionController
    def log_page_views(options = nil)
      @log_page_view_options = options || {}
      include ::LogPageViews
    end

    def skip_log_page_views(options = {})
      raise ArgumentException.new("EffectiveLogging error: skip_log_page_views called without first having called log_page_views. Please add 'log_page_views' to your ApplicationController or this controller before using skip_log_page_views")
    end
  end

  included do
    # Break up the options
    logging_options = {} ; filter_options = {}
    @log_page_view_options.each do |k, v|
      [:details, :skip_namespace].include?(k) ? (logging_options[k] = v) : (filter_options[k] = v)
    end

    cattr_accessor :log_page_views_opts
    self.log_page_views_opts = logging_options

    # Set up the after_filter to do page logging
    after_filter :effective_logging_log_page_view, filter_options
  end

  module ClassMethods
    def skip_log_page_views(options = {})
      before_filter :skip_log_page_view, options
    end
  end

  def effective_logging_log_page_view
    return if @_effective_logging_skip_log_page_view == true
    return if (self.class.log_page_views_opts[:skip_namespace] || []).include?(self.class.parent)

    user = (current_user rescue nil)

    if self.class.log_page_views_opts[:details] == true
      EffectiveLogger.info(
        "page view: #{request.request_method} #{request.path}",
        :user => user,
        :params => request.params,
        :format => request.format.to_s,
        :referrer => request.referrer,
        :user_agent => request.user_agent
      )
    else
      EffectiveLogger.info("page view: #{request.request_method} #{request.path}", :user => user)
    end
  end

  def skip_log_page_view
    @_effective_logging_skip_log_page_view = true
  end

end

