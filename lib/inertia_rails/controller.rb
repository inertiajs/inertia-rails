# frozen_string_literal: true

module InertiaRails
  module Controller
    extend ActiveSupport::Concern

    included do
      helper ::InertiaRails::Helper

      before_action do
        InertiaRails::Current.request = request
      end

      after_action do
        cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
      end

      rescue_from InertiaRails::PrecognitionResponse do |e|
        render_precognition(e.errors)
      end
    end

    module ClassMethods
      def inertia_share(hash = nil, **props, &block)
        options = props.slice(:if, :unless, :only, :except)
        data = hash || props.except(:if, :unless, :only, :except)

        before_action(**options) do
          @_inertia_shared ||= []
          @_inertia_shared << data.freeze if data.any?
          @_inertia_shared << block if block
        end
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
          @_inertia_skip_props = view_assigns.keys + %w[_inertia_skip_props _inertia_shared]
        end
      end

      def _inertia_configuration
        @_inertia_configuration ||= begin
          config = superclass.try(:_inertia_configuration) || ::InertiaRails.configuration
          @inertia_config&.with_defaults(config) || config
        end
      end
    end

    # Instance-level inertia_share for use in before_action callbacks
    def inertia_share(**props, &block)
      @_inertia_shared ||= []
      @_inertia_shared << props.freeze unless props.empty?
      @_inertia_shared << block if block
    end

    def default_render
      if inertia_configuration.default_render
        render(inertia: true)
      else
        super
      end
    end

    def redirect_to(options = {}, response_options = {})
      capture_inertia_session_options(response_options)
      super
    end

    def inertia_meta
      @inertia_meta ||= InertiaRails::MetaTagBuilder.new(self)
    end

    private

    def precognition!(model_or_errors)
      InertiaRails.precognition!(model_or_errors)
    end

    def precognition(model_or_errors)
      errors = InertiaRails::Precognition.validate(model_or_errors)
      return if errors.nil?

      render_precognition(errors)
      true
    end

    def render_precognition(errors)
      response.headers['Precognition'] = 'true'

      if errors.empty?
        response.headers['Precognition-Success'] = 'true'
        head :no_content
      else
        render json: { errors: errors }, status: :unprocessable_entity
      end
    end

    def inertia_view_assigns
      return {} unless @_inertia_instance_props

      view_assigns.except(*@_inertia_skip_props)
    end

    def inertia_configuration
      self.class._inertia_configuration.bind_controller(self)
    end

    def inertia_shared_data
      initial_data =
        if session[:inertia_errors].present?
          { errors: session[:inertia_errors] }
        elsif inertia_configuration.always_include_errors_hash
          { errors: {} }
        else
          if inertia_configuration.always_include_errors_hash.nil?
            InertiaRails.deprecator.warn(
              'To comply with the Inertia protocol, an empty errors hash `{errors: {}}` ' \
              'will be included to all responses by default starting with InertiaRails 4.0. ' \
              'To opt-in now, set `config.always_include_errors_hash = true`. ' \
              'To disable this warning, set it to `false`.'
            )
          end
          {}
        end

      (@_inertia_shared || []).filter_map do |shared_data|
        if shared_data.respond_to?(:call)
          instance_exec(&shared_data)
        else
          shared_data
        end
      end.reduce(initial_data, &:merge)
    end

    def inertia_location(url)
      headers['X-Inertia-Location'] = url
      head :conflict
    end

    def inertia_collect_flash_data
      flash_data = flash.to_hash

      allowed_keys = inertia_configuration.flash_keys
      result = allowed_keys ? flash_data.slice(*allowed_keys.map(&:to_s)) : {}

      result.merge!(flash_data['inertia'].transform_keys(&:to_s)) if flash_data['inertia'].is_a?(Hash)

      result.symbolize_keys
    end

    def capture_inertia_session_options(options)
      return unless (inertia = options[:inertia])

      if (inertia_errors = inertia[:errors])
        if inertia_errors.respond_to?(:to_hash)
          session[:inertia_errors] = inertia_errors.to_hash
        else
          InertiaRails.deprecator.warn(
            'Object passed to `inertia: { errors: ... }` must respond to `to_hash`. Pass a hash-like object instead.'
          )
          session[:inertia_errors] = inertia_errors
        end
      end

      session[:inertia_clear_history] = inertia[:clear_history] if inertia[:clear_history]
      session[:inertia_preserve_fragment] = true if inertia[:preserve_fragment]
    end
  end
end
