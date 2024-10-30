require_relative "inertia_rails"
require_relative "helper"

module InertiaRails
  module Controller
    extend ActiveSupport::Concern

    included do
      helper ::InertiaRails::Helper

      after_action do
        cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
      end
    end

    module ClassMethods
      def inertia_share(attrs = {}, &block)
        @inertia_share ||= []
        @inertia_share << attrs.freeze unless attrs.empty?
        @inertia_share << block if block
      end

      def inertia_config(**attrs)
        config = InertiaRails::Configuration.new(**attrs)

        if @inertia_config
          @inertia_config.merge!(config)
        else
          @inertia_config = config
        end
      end

      def use_inertia_instance_props
        before_action do
          @_inertia_instance_props = true
          @_inertia_skip_props = view_assigns.keys + ['_inertia_skip_props']
        end
      end

      def _inertia_configuration
        @_inertia_configuration ||= begin
          config = superclass.try(:_inertia_configuration) || ::InertiaRails.configuration
          @inertia_config&.with_defaults(config) || config
        end
      end

      def _inertia_shared_data
        @_inertia_shared_data ||= begin
          shared_data = superclass.try(:_inertia_shared_data)

          if @inertia_share && shared_data.present?
            shared_data + @inertia_share.freeze
          else
            @inertia_share || shared_data || []
          end.freeze
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

    private

    def inertia_view_assigns
      return {} unless @_inertia_instance_props
      view_assigns.except(*@_inertia_skip_props)
    end

    def inertia_configuration
      self.class._inertia_configuration.bind_controller(self)
    end

    def inertia_shared_data
      initial_data = session[:inertia_errors].present? ? {errors: session[:inertia_errors]} : {}

      self.class._inertia_shared_data.filter_map { |shared_data|
        if shared_data.respond_to?(:call)
          instance_exec(&shared_data)
        else
          shared_data
        end
      }.reduce(initial_data, &:merge)
    end

    def inertia_location(url)
      headers['X-Inertia-Location'] = url
      head :conflict
    end

    def capture_inertia_errors(options)
      if (inertia_errors = options.dig(:inertia, :errors))
        session[:inertia_errors] = inertia_errors.to_hash
      end
    end
  end
end
