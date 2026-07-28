# frozen_string_literal: true

module InertiaRails
  module Devtools
    # Resolves the matched route into the name/uri/action the Route tab shows.
    module RouteLocator
      ROUTE_KEY = 'inertia_rails.devtools_route'

      class << self
        def resolve(request)
          controller = request.env['action_controller.instance']
          uri = uri_pattern(request)
          name = route_name(request)
          action = action_name(controller, request)

          return if uri.nil? && name.nil? && action.nil?

          { name: name, uri: uri, action: action }.tap do |route|
            source = action_source(controller)
            route[:actionSource] = source if source
          end
        end

        private

        def uri_pattern(request)
          pattern = request.respond_to?(:route_uri_pattern) ? request.route_uri_pattern : nil
          pattern ||= journey_route(request)&.path&.spec.to_s.presence
          pattern&.sub(/\(\.:format\)\z/, '')
        end

        def route_name(request)
          journey_route(request)&.name
        end

        def action_name(controller, request)
          return "#{controller.class.name}##{controller.action_name}" if controller

          params = request.path_parameters
          return unless params[:controller] && params[:action]

          "#{params[:controller]}##{params[:action]}"
        end

        def action_source(controller)
          return unless controller

          SourceLocator.method_source(controller.class, controller.action_name)
        end

        # Journey is the only place the route *name* is exposed; recognition is
        # cached per request because both lookups need it.
        def journey_route(request)
          return request.env[ROUTE_KEY] if request.env.key?(:__inertia_devtools_route)

          request.env[ROUTE_KEY] = begin
            found = nil
            Rails.application.routes.router.recognize(request) { |route, _params| found ||= route }
            found
          rescue StandardError
            nil
          end
        end
      end
    end
  end
end
