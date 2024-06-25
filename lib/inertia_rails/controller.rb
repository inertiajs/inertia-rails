require_relative "inertia_rails"

module InertiaRails
  module Controller
    extend ActiveSupport::Concern

    included do
      before_action do
        # :inertia_errors are deleted from the session by the middleware
        InertiaRails.share(errors: session[:inertia_errors]) if session[:inertia_errors].present?
      end

      after_action do
        cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
      end
    end

    module ClassMethods
      def inertia_share(**args, &block)
        before_action do
          InertiaRails.share(**args) if args
          InertiaRails.share_block(block) if block
        end
      end

      def use_inertia_instance_props
        before_action do
          @_inertia_instance_props = true
          @_inertia_skip_props = view_assigns.keys + ['_inertia_skip_props']
        end
      end
    end

    def default_render
      if inertia_configuration.default_render
        render(inertia: true)
      else
        super
      end
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

    def inertia_configuration
      ::InertiaRails.configuration
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
  end
end
