require 'inertia_rails/renderer'
require 'inertia_rails/engine'

require 'patches/debug_exceptions'
require 'patches/better_errors'
require 'patches/request'

ActionController::Renderers.add :inertia do |component, options|
  InertiaRails::Renderer.new(
    component,
    self,
    request,
    response,
    method(:render),
    props: options[:props],
    view_data: options[:view_data],
  ).render
end

module InertiaRails
  class Error < StandardError; end
end

class ActionDispatch::Routing::Mapper
  def inertia(args, &block)
    route = args.keys.first
    component = args.values.first

    get(route => 'inertia_rails/static#static', defaults: {component: component})
  end
end
