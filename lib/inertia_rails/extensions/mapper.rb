# frozen_string_literal: true

module InertiaRails
  module InertiaMapper
    def inertia(*args, **options)
      defaults = options.delete(:defaults) || {}
      defaults = defaults.merge(props: options.delete(:props)) if options.key?(:props)
      source = devtools_render_source
      defaults = defaults.merge(InertiaRails::Devtools::RENDER_SOURCE_KEY => source) if source

      extract_routes(args, options).each do |route, component|
        get(route, to: StaticController.action(:static), defaults: defaults.merge(component: component), **options)
      end
    end

    private

    # Route defaults become path parameters, so this lands in `params` and the request
    # log on every hit — only pay that when DevTools will read it.
    def devtools_render_source
      InertiaRails::Devtools.swallow do
        next unless InertiaRails::Devtools.enabled?

        InertiaRails::Devtools::SourceLocator.caller_source(caller_locations(1, 30))
      end
    end

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
