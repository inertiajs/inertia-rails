require 'inertia/renderer'
require 'inertia/railtie'

ActionController::Renderers.add :inertia do |component, options|
  Inertia::Renderer.new(
    component,
    request,
    response,
    method(:render),
    props: options[:props],
    view_data: options[:view_data],
  ).render
end

module Inertia
end
