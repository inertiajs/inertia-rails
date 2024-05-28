require_relative "inertia_rails"

module InertiaRails
  module Controller
    extend ActiveSupport::Concern

    included do
      helper_method :inertia_headers

      before_action do
        error_sharing = proc do
          # :inertia_errors are deleted from the session by the middleware
          if @_request && session[:inertia_errors].present?
            { errors: session[:inertia_errors] }
          else
            {}
          end
        end

        @_inertia_shared_plain_data ||= {}
        @_inertia_shared_blocks ||= [error_sharing]
        @_inertia_html_headers ||= []
      end

      after_action do
        cookies['XSRF-TOKEN'] = form_authenticity_token unless !protect_against_forgery?
      end
    end

    module ClassMethods
      def inertia_share(hash = nil, &block)
        before_action do
          @_inertia_shared_plain_data = @_inertia_shared_plain_data.merge(hash) if hash
          @_inertia_shared_blocks = @_inertia_shared_blocks + [block] if block_given?
        end
      end

      def use_inertia_instance_props
        before_action do
          @_inertia_instance_props = true
          @_inertia_skip_props = view_assigns.keys + ['_inertia_skip_props']
        end
      end

      def share_plain_data(hash)
        @_inertia_shared_plain_data = @_inertia_shared_plain_data.merge(hash)
      end

      def share_block(&block)
        @_inertia_shared_blocks = @_inertia_shared_blocks + [block]
      end
    end

    def inertia_headers
      @_inertia_html_headers.join.html_safe
    end

    def inertia_headers=(value)
      @_inertia_html_headers = value
    end

    def default_render
      if InertiaRails.default_render?
        render(inertia: true)
      else
        super
      end
    end

    def shared_data
      # Theses variables are set in the before_action, but we need to ensure they are initialized when using renderer alone
      @_inertia_shared_plain_data ||= {}
      @_inertia_shared_blocks ||= []

      @_inertia_shared_plain_data.merge(evaluated_blocks)
    end

    def redirect_to(options = {}, response_options = {})
      capture_inertia_errors(response_options)
      super(options, response_options)
    end

    def redirect_back(fallback_location:, allow_other_host: true, **options)
      capture_inertia_errors(options)
      super(
        fallback_location: fallback_location,
        allow_other_host: allow_other_host,
        **options,
      )
    end

    def inertia_view_assigns
      return {} unless @_inertia_instance_props
      view_assigns.except(*@_inertia_skip_props)
    end

    private

    def inertia_layout
      layout = ::InertiaRails.layout

      # When the global configuration is not set, let Rails decide which layout
      # should be used based on the controller configuration.
      layout.nil? ? true : layout
    end

    def inertia_location(url)
      headers['X-Inertia-Location'] = url
      head :conflict
    end

    def capture_inertia_errors(options)
      if (inertia_errors = options.dig(:inertia, :errors))
        session[:inertia_errors] = inertia_errors
      end
    end

    def evaluated_blocks
      @_inertia_shared_blocks&.map { |block| instance_exec(&block) }&.reduce(&:merge) || {}
    end
  end
end
