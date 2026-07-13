# frozen_string_literal: true

module InertiaRails
  module InertiaMapper
    def inertia(*args, **options)
      defaults = options.delete(:defaults) || {}

      extract_routes(args, options).each do |route, component|
        get(route, to: StaticController.action(:static), defaults: defaults.merge(component: component), **options)
      end
    end

    private

    # The first hash pair is the route; any further String-keyed pairs are
    # additional routes. Symbol-keyed leftovers are route options (`on:`, `as:`).
    def extract_routes(args, options)
      return [route_with_default_component(args.first)] if args.any?

      route = options.keys.first
      routes = [[route, options.delete(route)]]
      options.keys.grep(String).each { |extra| routes << [extra, options.delete(extra)] }
      routes
    end

    def route_with_default_component(path)
      if resource_scope?
        [path,
         InertiaRails.configuration.component_path_resolver(
           path: [@scope[:module], @scope[:controller]].compact.join('/'), action: path
         )]
      elsif @scope[:module].blank?
        [path, path]
      else
        [path, InertiaRails.configuration.component_path_resolver(path: @scope[:module], action: path)]
      end
    end
  end
end
