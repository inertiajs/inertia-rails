# frozen_string_literal: true

module InertiaRails
  module Controller
    extend ActiveSupport::Concern

    included do
      helper ::InertiaRails::Helper

      before_action do
        InertiaRails::Current.request = request
      end

      # The same URL answers as HTML, Inertia JSON, or a partial reload; fold the
      # representation into the conditional-GET validator so they don't share an ETag.
      etag { inertia_conditional_get_variant }

      after_action do
        next unless protect_against_forgery?
        # Included into ActionController::Base, so this runs for non-Inertia
        # responses too — ActiveStorage images, where it only breaks CDN caching.
        next unless request.format.html? || request.xhr?
        next if XsrfCookieRefreshPolicy.skip?(self)

        cookies['XSRF-TOKEN'] = form_authenticity_token
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
      full_page = response_options.dig(:inertia, :full_page)
      validate_full_page_redirect_status!(response_options) if full_page
      capture_inertia_session_options(response_options)
      super.tap do
        convert_redirect_to_location_response! if full_page && request.inertia?
      end
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

    # nil for plain requests — compacted out of the ETag, so non-Inertia ETags are unchanged.
    def inertia_conditional_get_variant
      return unless request.inertia?

      request.env.filter_map { |key, value| "#{key}=#{value}" if key.start_with?('HTTP_X_INERTIA') }.sort
    end

    # Rails < 8: _normalize_options overwrites :layout with a resolved default,
    # making an explicit `layout: false` indistinguishable from "not provided".
    # Stash the original value so the renderer can tell the two apart.
    def _normalize_options(options)
      options[:_inertia_layout] = options[:layout] if options.key?(:inertia) && options.key?(:layout)
      super
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
      if request.inertia?
        headers['X-Inertia-Location'] = url
        head :conflict
      else
        redirect_to url, allow_other_host: true
      end
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

    def validate_full_page_redirect_status!(response_options)
      status = Rack::Utils.status_code(response_options.fetch(:status, :found))
      return if [301, 302, 303].include?(status)

      raise ArgumentError, "`inertia: { full_page: true }` requires a 301, 302, or 303 redirect (got #{status}): " \
                           'a full page visit always issues a GET, so it cannot preserve the HTTP method.'
    end

    # Rewrites the redirect `super` just built into an Inertia location response,
    # keeping everything else `redirect_to` did: URL resolution, flash, cookies.
    def convert_redirect_to_location_response!
      headers['X-Inertia-Location'] = headers.delete('Location')
      self.status = 409
      self.response_body = ''
    end
  end
end
