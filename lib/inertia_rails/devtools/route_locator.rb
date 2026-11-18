# frozen_string_literal: true

module InertiaRails
  module Devtools
    module RouteLocator
      class << self
        def resolve(request, controller)
          uri = request.try(:route_uri_pattern).to_s.delete_suffix('(.:format)')

          route = { name: matched_route(request)&.name, uri: uri, action: controller_action(request, controller) }
          source = action_source(request, controller)
          route[:actionSource] = source if source
          route
        end

        def action_source(request, controller)
          return unless controller
          return source(request) if controller.is_a?(StaticController)

          SourceLocator.method_source(controller.class, controller.action_name)
        end

        def source(request)
          location = matched_route(request)&.source_location
          return unless location

          file, _, line = location.rpartition(':')
          { file: Rails.root.join(file).to_s, line: line.to_i }
        end

        private

        # Only Rails 8.1+ keeps the matched route.
        def matched_route(request)
          request.get_header('action_dispatch.route')
        end

        def controller_action(request, controller)
          return "#{controller.class.name}##{controller.action_name}" if controller

          params = request.path_parameters
          return unless params[:controller] && params[:action]

          "#{params[:controller]}##{params[:action]}"
        end
      end
    end
  end
end
