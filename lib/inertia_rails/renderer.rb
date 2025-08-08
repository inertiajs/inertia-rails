# frozen_string_literal: true

require 'net/http'
require 'json'
require_relative 'inertia_rails'

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

    def initialize(component, controller, request, response, render_method, **options)
      if component.is_a?(Hash) && options.key?(:props)
        raise ArgumentError,
              'Parameter `props` is not allowed when passing a Hash as the first argument'
      end

      @controller = controller
      @configuration = controller.__send__(:inertia_configuration)
      @component = resolve_component(component)
      @request = request
      @response = response
      @render_method = render_method
      @props = options.fetch(:props, component.is_a?(Hash) ? component : controller.__send__(:inertia_view_assigns))
      @view_data = options.fetch(:view_data, {})
      @deep_merge = options.fetch(:deep_merge, configuration.deep_merge_shared_data)
      @encrypt_history = options.fetch(:encrypt_history, configuration.encrypt_history)
      @clear_history = options.fetch(:clear_history, controller.session[:inertia_clear_history] || false)
      @controller.instance_variable_set('@_inertia_rendering', true)
      controller.inertia_meta.add(options[:meta]) if options[:meta]
    end

    def render
      @response.headers['Vary'] = if @response.headers['Vary'].blank?
                                    'X-Inertia'
                                  else
                                    "#{@response.headers['Vary']}, X-Inertia"
                                  end
      if @request.headers['X-Inertia']
        @response.set_header('X-Inertia', 'true')
        @render_method.call json: page.to_json, status: @response.status, content_type: Mime[:json]
      else
        begin
          return render_ssr if configuration.ssr_enabled
        rescue StandardError
          nil
        end
        controller.instance_variable_set('@_inertia_page', page)
        @render_method.call template: 'inertia', layout: layout, locals: view_data.merge(page: page)
      end
    end

    private

    def render_ssr
      uri = URI("#{configuration.ssr_url}/render")
      res = JSON.parse(Net::HTTP.post(uri, page.to_json, 'Content-Type' => 'application/json').body)

      controller.instance_variable_set('@_inertia_ssr_head', res['head'].join.html_safe)
      @render_method.call html: res['body'].html_safe, layout: layout, locals: view_data.merge(page: page)
    end

    def layout
      layout = configuration.layout
      layout.nil? || layout
    end

    def shared_data
      controller.__send__(:inertia_shared_data)
    end

    # Cast props to symbol keyed hash before merging so that we have a consistent data structure and
    # avoid duplicate keys after merging.
    #
    # Functionally, this permits using either string or symbol keys in the controller. Since the results
    # is cast to json, we should treat string/symbol keys as identical.
    def merge_props(shared_props, props)
      if @deep_merge
        shared_props.deep_symbolize_keys.deep_merge!(props.deep_symbolize_keys)
      else
        shared_props.symbolize_keys.merge(props.symbolize_keys)
      end
    end

    def computed_props
      merge_props(shared_data, props)
        # This performs the internal work of hydrating/filtering props
        .then { |props| deep_transform_props(props) }
        # Then we apply the user-defined prop transformer
        .then { |props| configuration.prop_transformer(props: props) }
        # Then we add meta tags after everything since they must not be transformed
        .tap { |props| props[:_inertia_meta] = meta_tags if meta_tags.present? }
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

      deep_merge_props, merge_props = all_merge_props.partition do |_key, prop|
        prop.deep_merge?
      end

      match_props_on = all_merge_props.filter_map do |key, prop|
        prop.match_on.map { |ms| "#{key}.#{ms}" } if prop.match_on.present?
      end.flatten

      default_page[:mergeProps] = merge_props.map(&:first) if merge_props.present?
      default_page[:deepMergeProps] = deep_merge_props.map(&:first) if deep_merge_props.present?
      default_page[:matchPropsOn] = match_props_on if match_props_on.present?

      default_page
    end

    def deep_transform_props(props, parent_path = [])
      props.each_with_object({}) do |(key, prop), transformed_props|
        current_path = parent_path + [key]

        if prop.is_a?(Hash) && prop.any?
          nested = deep_transform_props(prop, current_path)
          transformed_props[key] = nested unless nested.empty?
        elsif keep_prop?(prop, current_path)
          transformed_props[key] =
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
    end

    def deferred_props_keys
      return if rendering_partial_component?

      @props.each_with_object({}) do |(key, prop), result|
        (result[prop.group] ||= []) << key if prop.is_a?(DeferProp)
      end
    end

    def all_merge_props
      @all_merge_props ||= @props.select do |key, prop|
        next unless prop.try(:merge?)
        next if reset_keys.include?(key)
        next if rendering_partial_component? && (
          (partial_keys.present? && partial_keys.exclude?(key.name)) ||
            (partial_except_keys.present? && partial_except_keys.include?(key.name))
        )

        true
      end
    end

    def partial_keys
      @partial_keys ||= (@request.headers['X-Inertia-Partial-Data'] || '').split(',').compact
    end

    def reset_keys
      (@request.headers['X-Inertia-Reset'] || '').split(',').compact.map(&:to_sym)
    end

    def partial_except_keys
      (@request.headers['X-Inertia-Partial-Except'] || '').split(',').compact
    end

    def rendering_partial_component?
      @request.headers['X-Inertia-Partial-Component'] == component
    end

    def resolve_component(component)
      if component == true || component.is_a?(Hash)
        configuration.component_path_resolver(path: controller.controller_path, action: controller.action_name)
      else
        component
      end
    end

    def keep_prop?(prop, path)
      return true if prop.is_a?(AlwaysProp)

      if rendering_partial_component? && (partial_keys.present? || partial_except_keys.present?)
        path_with_prefixes = path_prefixes(path)
        return false if excluded_by_only_partial_keys?(path_with_prefixes)
        return false if excluded_by_except_partial_keys?(path_with_prefixes)
      end

      # Precedence: Evaluate IgnoreOnFirstLoadProp only after partial keys have been checked
      return false if prop.is_a?(IgnoreOnFirstLoadProp) && !rendering_partial_component?

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

    def meta_tags
      controller.inertia_meta.meta_tags
    end
  end
end
