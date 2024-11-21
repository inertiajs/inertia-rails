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
    )

    def initialize(component, controller, request, response, render_method, props: nil, view_data: nil, deep_merge: nil)
      @controller = controller
      @configuration = controller.__send__(:inertia_configuration)
      @component = resolve_component(component)
      @request = request
      @response = response
      @render_method = render_method
      @props = props || controller.__send__(:inertia_view_assigns)
      @view_data = view_data || {}
      @deep_merge = !deep_merge.nil? ? deep_merge : configuration.deep_merge_shared_data
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
      _props = merge_props(shared_data, props)

      deep_transform_props _props do |prop, path|
        next [:dont_keep] unless keep_prop?(prop, path)

        transformed_prop = case prop
        when BaseProp
          prop.call(controller)
        when Proc
          controller.instance_exec(&prop)
        else
          prop
        end

        [:keep, transformed_prop]
      end
    end

    def page
      {
        component: component,
        props: computed_props,
        url: @request.original_fullpath,
        version: configuration.version,
      }
    end

    def deep_transform_props(props, parent_path = [], &block)
      props.reduce({}) do |transformed_props, (key, prop)|
        current_path = parent_path + [key]

        if prop.is_a?(Hash) && prop.any?
          nested = deep_transform_props(prop, current_path, &block)
          transformed_props.merge!(key => nested) unless nested.empty?
        else
          action, transformed_prop = block.call(prop, current_path)
          transformed_props.merge!(key => transformed_prop) if action == :keep
        end

        transformed_props
      end
    end

    def partial_keys
      (@request.headers['X-Inertia-Partial-Data'] || '').split(',').compact
    end

    def partial_except_keys
      (@request.headers['X-Inertia-Partial-Except'] || '').split(',').compact
    end

    def rendering_partial_component?
      @request.headers['X-Inertia-Partial-Component'] == component
    end

    def resolve_component(component)
      return component unless component.is_a? TrueClass

      configuration.component_path_resolver(path: controller.controller_path, action: controller.action_name)
    end

    def keep_prop?(prop, path)
      return true if prop.is_a?(AlwaysProp)

      if rendering_partial_component?
        path_with_prefixes = path_prefixes(path)
        return false if excluded_by_only_partial_keys?(path_with_prefixes)
        return false if excluded_by_except_partial_keys?(path_with_prefixes)
      end

      # Precedence: Evaluate LazyProp only after partial keys have been checked
      return false if prop.is_a?(LazyProp) && !rendering_partial_component?

      true
    end

    def path_prefixes(parts)
      (0...parts.length).map do |i|
        parts[0..i].join('.')
      end
    end

    def excluded_by_only_partial_keys?(path_with_prefixes)
      partial_keys.present? && (path_with_prefixes & partial_keys).empty?
    end

    def excluded_by_except_partial_keys?(path_with_prefixes)
      partial_except_keys.present? && (path_with_prefixes & partial_except_keys).any?
    end
  end
end
