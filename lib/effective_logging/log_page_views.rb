module EffectiveLogging
  module LogPageViews

    module ActionController
      def log_page_views(options = nil)
        @log_page_view_options = options || {}

        include EffectiveLogging::LogPageViews::InstanceMethods
        extend EffectiveLogging::LogPageViews::ClassMethods

        # Break up the options
        logging_options = {} ; filter_options = {}
        (@log_page_view_options || {}).each do |k, v|
          [:details, :skip_namespace].include?(k) ? (logging_options[k] = v) : (filter_options[k] = v)
        end

        cattr_accessor :log_page_views_opts
        self.log_page_views_opts = logging_options

        # Set up the after_filter to do page logging
        after_action :effective_logging_log_page_view, filter_options
      end

      def skip_log_page_views(options = {})
        # Nothing
      end

    end

    module ClassMethods
      def skip_log_page_views(options = {})
        before_action :skip_log_page_view, options
      end
    end

    module InstanceMethods
      def effective_logging_log_page_view
        return if EffectiveLogging.supressed?
        return if @_effective_logging_skip_log_page_view == true
        return if (self.class.log_page_views_opts[:skip_namespace] || []).include?(self.class.ancestors.first)

        user = EffectiveLogging.current_user || (current_user if respond_to?(:current_user))

        if self.class.log_page_views_opts[:details] == false
          ::EffectiveLogger.view("#{request.request_method} #{request.path}", user: user)
        else
          ::EffectiveLogger.view(
            "#{request.request_method} #{request.path}",
            user: user,
            format: (request.format.to_s == 'text/html' ? nil : request.format.to_s),
            params: request.filtered_parameters.reject { |k, v| (k == 'controller' || k == 'action') },
            request: request
          )
        end
      end

      def skip_log_page_view
        @_effective_logging_skip_log_page_view = true
      end

      def skip_log_page_views
        @_effective_logging_skip_log_page_view = true
      end

    end

  end
end
