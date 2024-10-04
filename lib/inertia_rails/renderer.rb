require_relative "inertia_rails"

module InertiaRails
  class Renderer
    attr_reader :component, :view_data

    def initialize(component, controller, request, response, render_method, props: nil, view_data: nil, deep_merge: nil)
      @component = component.is_a?(TrueClass) ? "#{controller.controller_path}/#{controller.action_name}" : component
      @controller = controller
      @request = request
      @response = response
      @render_method = render_method
      @props = props ? props : controller.inertia_view_assigns
      @view_data = view_data || {}
      @deep_merge = !deep_merge.nil? ? deep_merge : InertiaRails.deep_merge_shared_data?
    end

    def render
      if @request.headers['X-Inertia']
        @response.set_header('Vary', 'X-Inertia')
        @response.set_header('X-Inertia', 'true')
        @render_method.call json: page, status: @response.status, content_type: Mime[:json]
      else
        return render_ssr if ::InertiaRails.ssr_enabled? rescue nil
        @render_method.call template: 'inertia', layout: layout, locals: (view_data).merge({page: page})
      end
    end

    private

    def render_ssr
      uri = URI("#{::InertiaRails.ssr_url}/render")
      res = JSON.parse(Net::HTTP.post(uri, page.to_json, 'Content-Type' => 'application/json').body)

      @controller.inertia_headers = res['head']
      @render_method.call html: res['body'].html_safe, layout: layout, locals: (view_data).merge({page: page})
    end

    def layout
      @controller.send(:inertia_layout)
    end

    def computed_props
      # Cast props to symbol keyed hash before merging so that we have a consistent data structure and
      # avoid duplicate keys after merging.
      #
      # Functionally, this permits using either string or symbol keys in the controller. Since the results
      # is cast to json, we should treat string/symbol keys as identical.
      _props = @controller.shared_data.merge.deep_symbolize_keys.send(prop_merge_method, @props.deep_symbolize_keys).select do |key, prop|
        if rendering_partial_component?
          key.in? partial_keys
        else
          !prop.is_a?(InertiaRails::IgnoreFirstLoadProp)
        end
      end

      deep_transform_values(
        _props,
        lambda do |prop|
          prop.respond_to?(:call) ? @controller.instance_exec(&prop) : prop
        end
      )
    end

    def page
      default_page = {
        component: component,
        props: computed_props,
        url: @request.original_fullpath,
        version: ::InertiaRails.version,
      }

      deferred_props = deferred_props_keys
      default_page[:deferredProps] = deferred_props if deferred_props.present?

      default_page
    end

    def deep_transform_values(hash, proc)
      return proc.call(hash) unless hash.is_a? Hash

      hash.transform_values {|value| deep_transform_values(value, proc)}
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

    def rendering_partial_component?
      @request.inertia_partial? && @request.headers['X-Inertia-Partial-Component'] == component
    end

    def prop_merge_method
      @deep_merge ? :deep_merge : :merge
    end
  end
end
