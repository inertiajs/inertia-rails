# frozen_string_literal: true

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

      deep_merge = options.fetch(:deep_merge, @configuration.deep_merge_shared_data)
      passed_props = options.fetch(:props,
                                   component.is_a?(Hash) ? component : @controller.__send__(:inertia_view_assigns))
      @props = merge_props(shared_data, passed_props, deep_merge)

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
        begin
          return render_ssr if @configuration.ssr_enabled
        rescue StandardError
          nil
        end
        @controller.instance_variable_set('@_inertia_page', page)
        @render_method.call template: 'inertia', layout: layout, locals: @view_data.merge(page: page)
      end
    end

    private

    def render_ssr
      uri = URI("#{@configuration.ssr_url}/render")
      res = JSON.parse(Net::HTTP.post(uri, page.to_json, 'Content-Type' => 'application/json').body)

      @controller.instance_variable_set('@_inertia_ssr_head', res['head'].join.html_safe)
      @render_method.call html: res['body'].html_safe, layout: layout, locals: @view_data.merge(page: page)
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

    def page
      return @page if defined?(@page)

      resolver = PropsResolver.new(
        @props,
        evaluator: PropEvaluator.new(@controller),
        visit: {
          component: @request.headers['X-Inertia-Partial-Component'] == @component,
          only: parse_header('X-Inertia-Partial-Data'),
          except: parse_header('X-Inertia-Partial-Except'),
          reset: parse_header('X-Inertia-Reset').map!(&:to_sym),
          except_once: parse_header('X-Inertia-Except-Once-Props'),
        },
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

    def parse_header(name)
      (@request.headers[name] || '').split(',').compact_blank!
    end
  end
end
