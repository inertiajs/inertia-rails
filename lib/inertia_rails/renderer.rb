# frozen_string_literal: true

require 'net/http'
require 'json'
require_relative "inertia_rails"

module InertiaRails
  class Renderer
    attr_reader(
      :component,
      :configuration,
      :controller,
      :props,
      :view_data,
      :encrypt_history,
      :clear_history
    )

    def initialize(component, controller, request, response, render_method, props: nil, view_data: nil, deep_merge: nil, encrypt_history: nil, clear_history: nil)
      @controller = controller
      @configuration = controller.__send__(:inertia_configuration)
      @component = resolve_component(component)
      @request = request
      @response = response
      @render_method = render_method
      @props = props || controller.__send__(:inertia_view_assigns)
      @view_data = view_data || {}
      @deep_merge = !deep_merge.nil? ? deep_merge : configuration.deep_merge_shared_data
      @encrypt_history = !encrypt_history.nil? ? encrypt_history : configuration.encrypt_history
      @clear_history = clear_history || controller.session[:inertia_clear_history] || false
    end

    def render
      if @response.headers["Vary"].blank?
        @response.headers["Vary"] = 'X-Inertia'
      else
        @response.headers["Vary"] = "#{@response.headers["Vary"]}, X-Inertia"
      end
      if @request.headers['X-Inertia']
        @response.set_header('X-Inertia', 'true')
        @render_method.call json: page, status: @response.status, content_type: Mime[:json]
      else
        return render_ssr if configuration.ssr_enabled rescue nil
        @render_method.call template: 'inertia', layout: layout, locals: view_data.merge(page: page)
      end
    end

    private

    def render_ssr
      uri = URI("#{configuration.ssr_url}/render")
      res = JSON.parse(Net::HTTP.post(uri, page.to_json, 'Content-Type' => 'application/json').body)

      controller.instance_variable_set("@_inertia_ssr_head", res['head'].join.html_safe)
      @render_method.call html: res['body'].html_safe, layout: layout, locals: view_data.merge(page: page)
    end

    def layout
      layout = configuration.layout
      layout.nil? ? true : layout
    end

    def shared_data
      controller.__send__(:inertia_shared_data)
    end

    # Cast props to symbol keyed hash before merging so that we have a consistent data structure and
    # avoid duplicate keys after merging.
    #
    # Functionally, this permits using either string or symbol keys in the controller. Since the results
    # is cast to json, we should treat string/symbol keys as identical.
    def merge_props(shared_data, props)
      if @deep_merge
        shared_data.deep_symbolize_keys.deep_merge!(props.deep_symbolize_keys)
      else
        shared_data.symbolize_keys.merge(props.symbolize_keys)
      end
    end

    def computed_props
      _props = merge_props(shared_data, props).select do |key, prop|
        if rendering_partial_component?
          partial_keys.none? || key.in?(partial_keys) || prop.is_a?(AlwaysProp)
        else
          !prop.is_a?(IgnoreOnFirstLoadProp)
        end
      end

      drop_partial_except_keys(_props) if rendering_partial_component?

      deep_transform_values _props do |prop|
        case prop
        when BaseProp
          prop.call(controller)
        when Proc
          controller.instance_exec(&prop)
        else
          prop
        end
      end
    end

    def page
      default_page = {
        component: component,
        props: computed_props,
        url: @request.original_fullpath,
        version: configuration.version,
        encryptHistory: encrypt_history,
        clearHistory: clear_history,
      }

      deferred_props = deferred_props_keys
      default_page[:deferredProps] = deferred_props if deferred_props.present?

      default_page
    end

    def deep_transform_values(hash, &block)
      return block.call(hash) unless hash.is_a? Hash

      hash.transform_values {|value| deep_transform_values(value, &block)}
    end

    def drop_partial_except_keys(hash)
      partial_except_keys.each do |key|
        parts = key.to_s.split('.').map(&:to_sym)
        *initial_keys, last_key = parts
        current = initial_keys.any? ? hash.dig(*initial_keys) : hash

        current.delete(last_key) if current.is_a?(Hash) && !current[last_key].is_a?(AlwaysProp)
      end
    end

    def deferred_props_keys
      return if rendering_partial_component?

      @props.select { |_, prop| prop.is_a?(DeferProp) }
            .map { |key, prop| { key: key, group: prop.group } }
            .group_by { |prop| prop[:group] }
            .transform_values { |props| props.map { |prop| prop[:key].to_s } }
    end

    def partial_keys
      (@request.headers['X-Inertia-Partial-Data'] || '').split(',').compact.map(&:to_sym)
    end

    def partial_except_keys
      (@request.headers['X-Inertia-Partial-Except'] || '').split(',').filter_map(&:to_sym)
    end

    def rendering_partial_component?
      @request.headers['X-Inertia-Partial-Component'] == component
    end

    def resolve_component(component)
      return component unless component.is_a? TrueClass

      configuration.component_path_resolver(path: controller.controller_path, action: controller.action_name)
    end
  end
end
