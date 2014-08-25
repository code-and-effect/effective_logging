module LogPageViews
  extend ActiveSupport::Concern

  module ActionController
    module ClassMethods
      def log_page_views(options = nil)
        @log_page_view_options = options || {}
        include ::LogPageViews
      end

      def skip_log_page_views(*args)
        Rails.logger.info "CALLED ACTIONCONTROLLER SKIP PAGE VIEW"

        self.instance_eval do
          before_filter :skip_log_page_view, *args
        end
      end

    end

    module InstanceMethods
      def skip_log_page_view
        @_effective_logging_skip_log_page_view = true
      end
    end
  end

  included do
    # Break up the options
    logging_options = {}
    filter_options = {}

    @log_page_view_options.each do |k, v|
      if [:except, :only, :if, :unless].include?(k)
        filter_options[k] = v
      else
        logging_options[k] = v
      end
    end

    # Store our Logging Options for later
    self.send(:define_method, 'effective_logging_log_page_views_options') { logging_options }

    # Set up the after_filter to do page logging
    after_filter :effective_logging_log_page_view, filter_options
  end

  module ClassMethods
    def skip_log_page_views
      Rails.logger.info "CALLED CLASS SKIP_LOG_PAGE_VIEWS"
      Rails.logger.info self
    end
  end

  def effective_logging_log_page_view
    return if @_effective_logging_skip_log_page_view
    return if (effective_logging_log_page_views_options[:skip_namespace] || []).include?(self.class.parent)

    user = (current_user rescue nil)

    if effective_logging_log_page_views_options[:details] == true
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


end

