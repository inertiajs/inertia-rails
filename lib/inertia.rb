require 'inertia/renderer'
require 'inertia/engine'

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
  class Error < StandardError; end
end
