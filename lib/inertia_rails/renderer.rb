require_relative "inertia_rails"
require 'net/http'

module InertiaRails
  class Renderer
    attr_reader :component, :view_data

    def initialize(component, controller, request, response, render_method, props:, view_data:, ssr: nil)
      @component = component
      @controller = controller
      @request = request
      @response = response
      @render_method = render_method
      @props = props || {}
      @view_data = view_data || {}
      @ssr_template_option = ssr
    end

    def render
      if @request.headers['X-Inertia']
        @response.set_header('Vary', 'Accept')
        @response.set_header('X-Inertia', 'true')
        @render_method.call json: page, status: @response.status, content_type: Mime[:json]
      elsif ssr? and check_ssr_running
        begin
          perform_ssr
        rescue StandardError => e
          Rails.logger.error "Error while performing SSR: #{e}, fallback to default handling"
            @render_method.call template: 'inertia', layout: ::InertiaRails.layout, locals: (view_data).merge({page: page})
        end
      else
        @render_method.call template: 'inertia', layout: ::InertiaRails.layout, locals: (view_data).merge({page: page})
      end
    end

    private

    def ssr?
      InertiaRails.ssr_enabled && @ssr_template_option != false
    end

    def perform_ssr
      ssr_uri = URI("http://#{InertiaRails.ssr_host}:#{InertiaRails.ssr_port}/render")
      ssr_response = Net::HTTP.post(ssr_uri, page.to_json, { "Content-Type" => "application/json" })
      unless ssr_response.code == "200"
        raise StandardError.new("Error while contacting ssr server: Status: #{ssr_response.code}\n#{ssr_response.body.read}")
      end
      body = JSON.parse(ssr_response.body)

      @render_method.call html: body['body'].html_safe, layout: ::InertiaRails.layout, locals: (view_data).merge({page: page, ssr_headers: body['head'] || []})
    end

    def check_ssr_running
      Socket.tcp(InertiaRails.ssr_host, InertiaRails.ssr_port, connect_timeout: 0.01).close
      true
    rescue StandardError
      Rails.logger.warn "SSR server could not be reached: #{InertiaRails.ssr_host}:#{InertiaRails.ssr_port}!"
      false
    end

    def props
      _props = ::InertiaRails.shared_data(@controller).merge(@props).select do |key, prop|
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
