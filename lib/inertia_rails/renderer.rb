require_relative "inertia_rails"

module InertiaRails
  class Renderer
    attr_reader :component, :view_data

    def initialize(component, request, response, render_method, props:, view_data:)
      @component = component
      @request = request
      @response = response
      @render_method = render_method
      @props = props || {}
      @view_data = view_data || {}
    end

    def render
      if @request.headers['X-Inertia']
        @response.set_header('Vary', 'Accept')
        @response.set_header('X-Inertia', 'true')
        @render_method.call json: page, status: 200
      else
        @render_method.call template: 'inertia', layout: ::InertiaRails.layout, locals: (view_data).merge({page: page})
      end
    end

    private

    def props
      only = (@request.headers['X-Inertia-Partial-Data'] || '').split(',').compact.map(&:to_sym)

      _props = ::InertiaRails.shared_data.merge(@props)

      _props = (only.any? && @request.headers['X-Inertia-Partial-Component'] == component) ?
        _props.select {|key| key.in? only} :
        _props

      deep_transform_values(_props, lambda {|prop| prop.respond_to?(:call) ? prop.call : prop })
    end

    def page
      {
        component: component,
        props: props,
        url: @request.original_url,
        version: ::InertiaRails.version,
      }
    end

    def deep_transform_values(hash, proc)
      return proc.call(hash) unless hash.is_a? Hash

      hash.transform_values {|value| deep_transform_values(value, proc)}
    end
  end
end
