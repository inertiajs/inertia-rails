# frozen_string_literal: true

require 'net/http'
require 'json'
require_relative 'inertia_rails'

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

    def computed_props
      # rubocop:disable Style/MultilineBlockChain
      @props
        .tap do |merged_props|
        # Always keep errors in the props
        if merged_props.key?(:errors) && !merged_props[:errors].is_a?(BaseProp)
          errors = merged_props[:errors]
          merged_props[:errors] = InertiaRails.always { errors }
        end
      end
        .then { |props| deep_transform_props(props) } # Internal hydration/filtering
        .then { |props| @configuration.prop_transformer(props: props) } # Apply user-defined prop transformer
        .tap do |props|
        # Add meta tags last (never transformed)
        props[:_inertia_meta] = meta_tags if meta_tags.present?
      end
      # rubocop:enable Style/MultilineBlockChain
    end

    def page
      return @page if defined?(@page)

      @page = {
        component: @component,
        props: computed_props,
        url: @request.original_fullpath,
        version: @configuration.version,
        encryptHistory: @encrypt_history,
        clearHistory: @clear_history,
      }

      flash_data = @controller.__send__(:inertia_collect_flash_data)
      @page[:flash] = flash_data if flash_data.present?

      deferred_props = deferred_props_keys
      @page[:deferredProps] = deferred_props if deferred_props.present?
      @page[:scrollProps] = scroll_props if scroll_props.present?
      @page.merge!(resolve_merge_props)

      once_props = resolve_once_props
      @page[:onceProps] = once_props if once_props.present?

      @page
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
              prop.call(@controller)
            when Proc
              @controller.instance_exec(&prop)
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

    def resolve_merge_props
      deep_merge_props, merge_props = all_merge_props.partition do |_key, prop|
        prop.deep_merge?
      end

      {
        mergeProps: append_merge_props(merge_props),
        prependProps: prepend_merge_props(merge_props),
        deepMergeProps: deep_merge_props.map!(&:first),
        matchPropsOn: resolve_match_on_props,
      }.delete_if { |_, v| v.blank? }
    end

    def resolve_once_props
      @props.each_with_object({}) do |(key, prop), result|
        next unless prop.try(:once?)
        next if excluded_by_partial_request?([key.to_s])

        once_key = (prop.once_key || key).to_s

        result[once_key] = { prop: key.to_s, expiresAt: prop.expires_at }.compact
      end
    end

    def resolve_match_on_props
      all_merge_props.filter_map do |key, prop|
        prop.match_on.map! { |ms| "#{key}.#{ms}" } if prop.match_on.present?
      end.flatten
    end

    def requested_merge_props
      @requested_merge_props ||= @props.select do |key, prop|
        next unless prop.try(:merge?)
        next if rendering_partial_component? && (
          (partial_keys.present? && partial_keys.exclude?(key.name)) ||
            (partial_except_keys.present? && partial_except_keys.include?(key.name))
        )

        true
      end
    end

    def append_merge_props(props)
      return props if props.empty?

      root_append_props, nested_append_props = props.partition { |_key, prop| prop.appends_at_root? }

      result = Set.new(root_append_props.map!(&:first))

      nested_append_props.each do |key, prop|
        prop.appends_at_paths.each do |path|
          result.add("#{key}.#{path}")
        end
      end

      result.to_a
    end

    def prepend_merge_props(props)
      return props if props.empty?

      root_prepend_props, nested_prepend_props = props.partition { |_key, prop| prop.prepends_at_root? }

      result = Set.new(root_prepend_props.map!(&:first))

      nested_prepend_props.each do |key, prop|
        prop.prepends_at_paths.each do |path|
          result.add("#{key}.#{path}")
        end
      end

      result.to_a
    end

    def scroll_props
      return @scroll_props if defined?(@scroll_props)

      @scroll_props = {}
      requested_merge_props.each do |key, prop|
        next unless prop.is_a?(ScrollProp)

        @scroll_props[key] = prop.metadata.merge!(reset: reset_keys.include?(key))
      end
      @scroll_props
    end

    def all_merge_props
      @all_merge_props ||= requested_merge_props.reject { |key,| reset_keys.include?(key) }
    end

    def partial_keys
      @partial_keys ||= (@request.headers['X-Inertia-Partial-Data'] || '').split(',').compact_blank!
    end

    def reset_keys
      @reset_keys ||= (@request.headers['X-Inertia-Reset'] || '').split(',').compact_blank!.map!(&:to_sym)
    end

    def partial_except_keys
      @partial_except_keys ||= (@request.headers['X-Inertia-Partial-Except'] || '').split(',').compact_blank!
    end

    def except_once_keys
      @except_once_keys ||= (@request.headers['X-Inertia-Except-Once-Props'] || '').split(',').compact_blank!
    end

    def rendering_partial_component?
      @request.headers['X-Inertia-Partial-Component'] == @component
    end

    def resolve_component(component)
      if component == true || component.is_a?(Hash)
        @configuration.component_path_resolver(path: @controller.controller_path, action: @controller.action_name)
      else
        component
      end
    end

    def keep_prop?(prop, path)
      return true if prop.is_a?(AlwaysProp)
      return false if excluded_by_once_cache?(prop, path)
      return false if excluded_by_partial_request?(path)

      # Precedence: Evaluate IgnoreOnFirstLoadProp only after partial keys have been checked
      return false if prop.is_a?(IgnoreOnFirstLoadProp) && !rendering_partial_component?

      true
    end

    def excluded_by_once_cache?(prop, path)
      return false unless prop.try(:once?)
      return false if prop.try(:fresh?)
      return false if explicitly_requested?(path)

      once_key = (prop.once_key || path.join('.')).to_s
      except_once_keys.include?(once_key)
    end

    def explicitly_requested?(path)
      return false unless rendering_partial_component? && partial_keys.present?

      path_with_prefixes = path_prefixes(path)
      (path_with_prefixes & partial_keys).any?
    end

    def excluded_by_partial_request?(path)
      return false unless rendering_partial_component? && (partial_keys.present? || partial_except_keys.present?)

      path_with_prefixes = path_prefixes(path)
      excluded_by_only_partial_keys?(path_with_prefixes) || excluded_by_except_partial_keys?(path_with_prefixes)
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
      @controller.inertia_meta.meta_tags
    end
  end
end
