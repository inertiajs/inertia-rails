# frozen_string_literal: true

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
      @layout_override = options.fetch(:layout) { @configuration.layout }
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
      ActiveSupport::Notifications.instrument('render.inertia_rails',
                                              component: @component, partial: partial_reload?, ssr: false) do |payload|
        vary = @response.headers['Vary'].to_s.split(',').map(&:strip).reject(&:empty?)
        vary << 'X-Inertia' if vary.none? { |value| value.casecmp?('X-Inertia') }
        @response.headers['Vary'] = vary.join(', ')
        if @request.inertia?
          @response.set_header('X-Inertia', 'true')
          @render_method.call json: page.to_json, status: @response.status, content_type: Mime[:json]
        else
          ssr = @configuration.ssr_enabled && ssr_render
          if ssr
            payload[:ssr] = true
            @controller.instance_variable_set('@_inertia_ssr_head', ssr['head'].join.html_safe)
            @render_method.call(
              html: ssr['body'].html_safe,
              layout: layout,
              locals: @view_data.merge(page: page),
              formats: :html
            )
          else
            @controller.instance_variable_set('@_inertia_page', page)
            @render_method.call(
              template: 'inertia',
              layout: layout,
              locals: @view_data.merge(page: page),
              formats: :html
            )
          end
        end
      end
    end

    private

    def ssr_render
      SSRRenderer.new(@configuration, page: page, cache: @ssr_cache).render
    end

    def layout
      layout = @layout_override
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

      @page = ActiveSupport::Notifications.instrument('resolve_props.inertia_rails',
                                                      component: @component, partial: partial_reload?) do
        build_page
      end
    end

    def partial_reload?
      @request.headers['X-Inertia-Partial-Component'] == @component
    end

    def build_page
      wrap_errors_prop!(@props)
      validate_meta_prop!

      resolver = PropsResolver.new(
        @props,
        evaluator: PropEvaluator.new(@controller,
                                     scroll_intent: @request.headers['X-Inertia-Infinite-Scroll-Merge-Intent']),
        visit: {
          component: partial_reload?,
          only: parse_header('X-Inertia-Partial-Data'),
          except: parse_header('X-Inertia-Partial-Except'),
          reset: parse_header('X-Inertia-Reset'),
          except_once: parse_header('X-Inertia-Except-Once-Props'),
        }
      )
      resolved_props, metadata = resolver.resolve

      resolved_props = @configuration.prop_transformer(props: resolved_props)

      # Add meta tags (never transformed by prop_transformer)
      merge_meta_tags!(resolved_props)

      page = {
        component: @component,
        props: resolved_props,
        url: @request.original_fullpath,
        version: @configuration.version,
        encryptHistory: @encrypt_history,
        clearHistory: @clear_history,
      }

      flash_data = @controller.__send__(:inertia_collect_flash_data)
      page[:flash] = flash_data if flash_data.present?

      page[:sharedProps] = @shared_keys if @shared_keys&.any?
      page[:preserveFragment] = @preserve_fragment if @preserve_fragment

      page.merge!(metadata)
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

    def apply_title_template
      return unless (template = @configuration.meta_title_template)

      meta = @controller.inertia_meta
      title = @controller.instance_exec(meta.title, &template)
      meta.add(title: title) if title.present?
    end

    def merge_meta_tags!(props)
      apply_title_template
      return if meta_tags.blank?

      props[@configuration.meta_prop] = serialized_meta_tags
    end

    def serialized_meta_tags
      return meta_tags unless @configuration.server_head

      attribute = @configuration.head_attribute
      meta_tags.map { |tag| tag.to_tag(inertia_attribute: attribute) }
    end

    def validate_meta_prop!
      return unless @configuration.server_head

      prop = @configuration.meta_prop
      return unless @props.key?(prop)

      raise Error, "The `#{prop}` prop is reserved by `config.server_head`. " \
                   'Rename the conflicting prop, or set `config.server_head` to a custom prop name.'
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
