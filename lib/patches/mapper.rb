module InertiaRails
  module InertiaMapper
    def inertia(*args, **options)
      path = args.any? ? args.first : options
      route, component = extract_route_and_component(path)
      get(route, to: StaticController.action(:static), defaults: { component: component }, **options)
    end

    private

    def extract_route_and_component(path)
      if path.is_a?(Hash)
        path.first
      elsif resource_scope?
        [path, InertiaRails.configuration.component_path_resolver(path: [@scope[:module], @scope[:controller]].compact.join('/'), action: path)]
      elsif @scope[:module].blank?
        [path, path]
      else
        [path, InertiaRails.configuration.component_path_resolver(path: @scope[:module], action: path)]
      end
    end
  end
end

ActionDispatch::Routing::Mapper.include InertiaRails::InertiaMapper
