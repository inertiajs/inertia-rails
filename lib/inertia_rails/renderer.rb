require 'net/http'
require 'json'
require_relative "inertia_rails"

module InertiaRails
  class Renderer
    attr_reader :component, :view_data

    def initialize(component = nil, controller, request, response, render_method, props:, view_data:)
      @component = component || "#{controller.controller_path}/#{controller.action_name}"
      @controller = controller
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
        @render_method.call json: page, status: @response.status, content_type: Mime[:json]
      else
        return render_ssr if ::InertiaRails.ssr_enabled? rescue nil
        @render_method.call template: 'inertia', layout: ::InertiaRails.layout, locals: (view_data).merge({page: page})
      end
    end

    private

    def render_ssr
      uri = URI("#{::InertiaRails.ssr_url}/render")
      res = JSON.parse(Net::HTTP.post(uri, page.to_json, 'Content-Type' => 'application/json').body)
      
      ::InertiaRails.html_headers = res['head']
      @render_method.call html: res['body'].html_safe, layout: ::InertiaRails.layout, locals: (view_data).merge({page: page})
    end

    def props
      _props = ::InertiaRails.shared_data(@controller).merge(controller_instance_variables).merge(@props).select do |key, prop|
        if rendering_partial_component?
          key.in? partial_keys
        else
          !prop.is_a?(InertiaRails::Lazy)
        end
      end

      deep_transform_values(_props, lambda {|prop| prop.respond_to?(:call) ? @controller.instance_exec(&prop) : prop })
    end

    def page
      {
        component: component,
        props: props,
        url: @request.original_fullpath,
        version: ::InertiaRails.version,
      }
    end

    def controller_instance_variables
      @controller.view_assigns.except('rendered_format', 'marked_for_same_origin_verification')
    end

    def deep_transform_values(hash, proc)
      return proc.call(hash) unless hash.is_a? Hash

      hash.transform_values {|value| deep_transform_values(value, proc)}
    end

    def partial_keys
      (@request.headers['X-Inertia-Partial-Data'] || '').split(',').compact.map(&:to_sym)
    end

    def rendering_partial_component?
      @request.inertia_partial? && @request.headers['X-Inertia-Partial-Component'] == component
    end
  end
end
