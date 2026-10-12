# frozen_string_literal: true

module InertiaRails
  # A Rails exceptions app that renders error pages with your controller:
  #
  #   config.exceptions_app = InertiaRails::ExceptionsApp.new(controller: 'ErrorsController')
  #
  # ActionDispatch::ShowExceptions calls it with PATH_INFO rewritten to "/<status>".
  # HTML requests for one of +statuses+ go to the controller's +show+ action;
  # everything else gets Rails' default ActionDispatch::PublicExceptions response.
  class ExceptionsApp
    DEFAULT_STATUSES = [403, 404, 500, 503].freeze

    def initialize(controller:, statuses: DEFAULT_STATUSES)
      @controller = controller
      @statuses = statuses.map { |status| Rack::Utils.status_code(status) }
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      status = request.path_info.delete_prefix('/').to_i

      if request.format.html? && @statuses.include?(status) && params_parse?(request)
        # ShowExceptions sits above these middlewares. Without InertiaRails::Middleware, a client
        # with stale assets would adopt the new version from the page; without Rack::ETag,
        # the page would get no Cache-Control header.
        Rack::ETag.new(Middleware.new(@controller.constantize.action(:show)), 'no-cache').call(env)
      else
        ActionDispatch::PublicExceptions.new(Rails.public_path).call(env)
      end
    end

    private

    # Rails' controller instrumentation reads the params, and raises when the failed
    # request's query string or form body doesn't parse.
    def params_parse?(request)
      request.filtered_parameters
      true
    rescue ActionController::BadRequest
      false
    end
  end
end
