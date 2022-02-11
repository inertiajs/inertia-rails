ActionDispatch::Routing::Mapper.class_eval do
  def inertia(args, &block)
    route = args.keys.first
    component = args.values.first

    get(route => 'inertia_rails/static#static', defaults: {component: component})
  end
end
