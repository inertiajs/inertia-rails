require 'inertia_rails/renderer'
require 'inertia_rails/engine'

ActionController::Renderers.add :inertia do |component, options|
  InertiaRails::Renderer.new(
    component,
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
