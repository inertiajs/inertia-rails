# frozen_string_literal: true

require 'digest/md5'
require 'net/http'
require 'json'
require_relative 'inertia_rails'
require_relative 'props_resolver'

module InertiaRails
  class Renderer
    %i[component configuration controller props view_data encrypt_history
       clear_history].each do |method_name|
      define_method(method_name) do
        InertiaRails.deprecator.warn(
          "[DEPRECATION] Accessing `InertiaRails::Renderer##{method_name}` is deprecated and will be removed in v4.0"
        )
        instance_variable_get("@#{method_name}")
      end
    end

    def initialize(component, controller, request, response, render_method, **options)
      if component.is_a?(Hash) && options.key?(:props)
        raise ArgumentError,
              'Parameter `props` is not allowed when passing a Hash as the first argument'
      end

      @controller = controller
      @configuration = controller.__send__(:inertia_configuration)
      @request = request
      @response = response
      @render_method = render_method
      @view_data = options.fetch(:view_data, {})
      @encrypt_history = options.fetch(:encrypt_history, @configuration.encrypt_history)
      @clear_history = options.fetch(:clear_history, controller.session[:inertia_clear_history] || false)
      @preserve_fragment = options.fetch(:preserve_fragment, controller.session[:inertia_preserve_fragment] || false)
      @ssr_cache = options[:ssr_cache]

      deep_merge = options.fetch(:deep_merge, @configuration.deep_merge_shared_data)
      passed_props = options.fetch(:props,
                                   component.is_a?(Hash) ? component : @controller.__send__(:inertia_view_assigns))
      shared = shared_data
      @shared_keys = @configuration.expose_shared_prop_keys ? extract_shared_keys(shared) : nil
      @props = merge_props(shared, passed_props, deep_merge)

      @component = resolve_component(component)

      @controller.instance_variable_set('@_inertia_rendering', true)
      controller.inertia_meta.add(options[:meta]) if options[:meta]
    end

    def render
      @response.headers['Vary'] = if @response.headers['Vary'].blank?
                                    'X-Inertia'
                                  else
                                    "#{@response.headers['Vary']}, X-Inertia"
                                  end
      if @request.inertia?
        @response.set_header('X-Inertia', 'true')
        @render_method.call json: page.to_json, status: @response.status, content_type: Mime[:json]
      else
        ssr = @configuration.ssr_enabled && ssr_render
        if ssr
          @controller.instance_variable_set('@_inertia_ssr_head', ssr['head'].join.html_safe)
          @render_method.call html: ssr['body'].html_safe, layout: layout, locals: @view_data.merge(page: page)
        else
          @controller.instance_variable_set('@_inertia_page', page)
          @render_method.call template: 'inertia', layout: layout, locals: @view_data.merge(page: page)
        end
      end
    end

    private

    def ssr_render
      return unless ssr_bundle_exists?

      if (cache_options = ssr_cache_options)
        Rails.cache.fetch(ssr_cache_key, **cache_options) { ssr_request }
      else
        ssr_request
      end
    rescue InertiaRails::SSRError => e
      handle_ssr_error(e)
    rescue StandardError => e
      handle_ssr_error(InertiaRails::SSRError.from_exception(e))
    end

    def ssr_request
      response = Net::HTTP.post(URI(ssr_url), page_json, 'Content-Type' => 'application/json')

      unless response.is_a?(Net::HTTPSuccess)
        body = begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          {}
        end
        body['error'] ||= "SSR server returned #{response.code}"
        raise InertiaRails::SSRError.from_response(body)
      end

      JSON.parse(response.body)
    end

    def handle_ssr_error(error)
      Rails.logger.error("[inertia-rails] SSR render failed: #{error.message}")
      @configuration.on_ssr_error&.call(error, page)
      raise error if @configuration.ssr_raise_on_error

      nil
    end

    def ssr_cache_options
      return if vite_dev_server_url

      raw = @ssr_cache.nil? ? @configuration.ssr_cache : @ssr_cache
      case raw
      when true then {}
      when Hash then raw
      end
    end

    def page_json
      @page_json ||= page.to_json
    end

    def ssr_cache_key
      "inertia_ssr/#{Digest::MD5.hexdigest(page_json)}"
    end

    def ssr_url
      if (dev_url = vite_dev_server_url)
        "#{dev_url}/__inertia_ssr"
      else
        "#{@configuration.ssr_url}/render"
      end
    end

    def vite_dev_server_url
      return @vite_dev_server_url if defined?(@vite_dev_server_url)

      @vite_dev_server_url = detect_vite_dev_url
    end

    def ssr_bundle_exists?
      return true if vite_dev_server_url

      bundle = @configuration.ssr_bundle
      return true if bundle.nil?

      Array(bundle).any? { |path| File.exist?(path) }
    end

    def detect_vite_dev_url
      # vite_rails: TCP probe, no metadata file
      if defined?(ViteRuby) && ViteRuby.instance.dev_server_running?
        config = ViteRuby.config
        return "#{config.protocol}://#{config.host_with_port}"
      end

      # rails_vite + jsbundling: file-based
      path = Rails.root.join('tmp/rails-vite.json')
      JSON.parse(path.read)['url'] if path.exist?
    rescue JSON::ParserError
      nil
    end

    def layout
      layout = @configuration.layout
      layout.nil? || layout
    end

    def shared_data
      @controller.__send__(:inertia_shared_data)
    end

    # Cast props to symbol keyed hash before merging so that we have a consistent data structure and
    # avoid duplicate keys after merging.
    #
    # Functionally, this permits using either string or symbol keys in the controller. Since the results
    # is cast to json, we should treat string/symbol keys as identical.
    def merge_props(shared_props, props, deep_merge)
      if deep_merge
        shared_props.deep_symbolize_keys.deep_merge!(props.deep_symbolize_keys)
      else
        shared_props.symbolize_keys.merge(props.symbolize_keys)
      end
    end

    def extract_shared_keys(shared_props)
      shared_props.keys.map { |key| key.to_s.split('.', 2).first }.uniq
    end

    def page
      return @page if defined?(@page)

      wrap_errors_prop!(@props)

      resolver = PropsResolver.new(
        @props,
        evaluator: PropEvaluator.new(@controller,
                                     scroll_intent: @request.headers['X-Inertia-Infinite-Scroll-Merge-Intent']),
        visit: {
          component: @request.headers['X-Inertia-Partial-Component'] == @component,
          only: parse_header('X-Inertia-Partial-Data'),
          except: parse_header('X-Inertia-Partial-Except'),
          reset: parse_header('X-Inertia-Reset'),
          except_once: parse_header('X-Inertia-Except-Once-Props'),
        }
      )
      resolved_props, metadata = resolver.resolve

      resolved_props = @configuration.prop_transformer(props: resolved_props)

      # Add meta tags (never transformed by prop_transformer)
      resolved_props[:_inertia_meta] = meta_tags if meta_tags.present?

      @page = {
        component: @component,
        props: resolved_props,
        url: @request.original_fullpath,
        version: @configuration.version,
        encryptHistory: @encrypt_history,
        clearHistory: @clear_history,
      }

      flash_data = @controller.__send__(:inertia_collect_flash_data)
      @page[:flash] = flash_data if flash_data.present?

      @page[:sharedProps] = @shared_keys if @shared_keys&.any?
      @page[:preserveFragment] = @preserve_fragment if @preserve_fragment

      @page.merge!(metadata)

      @page
    end

    def resolve_component(component)
      if component == true || component.is_a?(Hash)
        @configuration.component_path_resolver(path: @controller.controller_path, action: @controller.action_name)
      else
        component
      end
    end

    def meta_tags
      @controller.inertia_meta.meta_tags
    end

    def wrap_errors_prop!(props)
      return unless props.key?(:errors) && !props[:errors].is_a?(BaseProp)

      errors = props[:errors]
      props[:errors] = InertiaRails.always { errors }
    end

    def parse_header(name)
      (@request.headers[name] || '').split(',').compact_blank!
    end
  end
end
