module InertiaRails
  module InertiaMapper
    def inertia(args, &block)
      route = args.keys.first
      component = args.values.first

      get(route => 'inertia_rails/static#static', defaults: { component: component })
    end
  end
end

ActionDispatch::Routing::Mapper.include InertiaRails::InertiaMapper
