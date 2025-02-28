module InertiaRails
  module InertiaMapper
    def inertia(*args, **options)
      path = args.any? ? args.first : options
      route, component = extract_route_and_component(path)
      @scope = @scope.new(module: nil)
      get(route, to: 'inertia_rails/static#static', defaults: { component: component }, **options)
    ensure
      @scope = @scope.parent
    end

    private

    def extract_route_and_component(args)
      if args.is_a?(Hash)
        args.first
      elsif resource_scope?
        [args, InertiaRails.configuration.component_path_resolver(path: [@scope[:module], @scope[:controller]].compact.join('/'), action: args)]
      elsif @scope[:module].blank?
        [args, args]
      else
        [args, InertiaRails.configuration.component_path_resolver(path: @scope[:module], action: args)]
      end
    end
  end
end

ActionDispatch::Routing::Mapper.include InertiaRails::InertiaMapper
