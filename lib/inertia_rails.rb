# frozen_string_literal: true

require 'inertia_rails/version'
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
    **options
  ).render
end

module InertiaRails
  class Error < StandardError; end

  class SSRError < Error
    attr_reader :type, :hint, :browser_api, :stack, :source_location

    def initialize(message = nil, type: nil, hint: nil, browser_api: nil, stack: nil, source_location: nil)
      @type = type
      @hint = hint
      @browser_api = browser_api
      @stack = stack
      @source_location = source_location
      super(message)
    end

    def self.from_response(body)
      new(
        body['error'] || 'Unknown SSR error',
        type: body['type'],
        hint: body['hint'],
        browser_api: body['browserApi'],
        stack: body['stack'],
        source_location: body['sourceLocation']
      )
    end

    def self.from_exception(exception)
      error = new(exception.message, type: 'connection')
      error.set_backtrace(exception.backtrace)
      error
    end
  end

  def self.deprecator # :nodoc:
    @deprecator ||= ActiveSupport::Deprecation.new
  end
end
