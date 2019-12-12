require 'inertia_rails/renderer'
require 'inertia_rails/engine'
require 'inertia_rails/debug_exceptions'

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
