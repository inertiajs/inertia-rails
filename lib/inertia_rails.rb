require 'inertia_rails/renderer'
require 'inertia_rails/engine'

require 'patches/debug_exceptions'
require 'patches/better_errors'
require 'patches/request'
require 'patches/mapper'

ActionController::Renderers.add :inertia do |component, options|
  InertiaRails::Renderer.new(
    component,
    self,
    request,
    response,
    method(:render),
    props: options[:props],
    view_data: options[:view_data],
    deep_merge: options[:deep_merge],
  ).render
end

module InertiaRails
  class Error < StandardError; end

  def self.deprecator # :nodoc:
    @deprecator ||= ActiveSupport::Deprecation.new
  end

  def self.warn(message)
    full_message = "[InertiaRails]: WARNING! #{message}"
    Kernel.warn full_message if Rails.env.development? || Rails.env.test?
    Rails.logger.warn full_message
  end
end
