# frozen_string_literal: true

module InertiaRails
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      InertiaRailsRequest.new(@app, env).response
    end

    class InertiaRailsRequest
      def initialize(app, env)
        @app = app
        @env = env
      end

      def response
        copy_xsrf_to_csrf!
        status, headers, body = @app.call(@env)
        request = ActionDispatch::Request.new(@env)

        # Inertia errors are added to the session via redirect_to
        unless keep_inertia_session_options?(status)
          request.session.delete(:inertia_errors)
          request.session.delete(:inertia_clear_history)
        end

        status = 303 if inertia_non_post_redirect?(status)

        stale_inertia_get? ? force_refresh(request) : [status, headers, body]
      end

      private

      def keep_inertia_session_options?(status)
        redirect_status?(status) || stale_inertia_request?
      end

      def stale_inertia_request?
        inertia_request? && version_stale?
      end

      def redirect_status?(status)
        [301, 302].include? status
      end

      def non_get_redirectable_method?
        ['PUT', 'PATCH', 'DELETE'].include? request_method
      end

      def inertia_non_post_redirect?(status)
        inertia_request? && redirect_status?(status) && non_get_redirectable_method?
      end

      def stale_inertia_get?
        get? && stale_inertia_request?
      end

      def get?
        request_method == 'GET'
      end

      def controller
        @env["action_controller.instance"]
      end

      def request_method
        @env['REQUEST_METHOD']
      end

      def client_version
        @env['HTTP_X_INERTIA_VERSION']
      end

      def inertia_request?
        @env['HTTP_X_INERTIA'].present?
      end

      def version_stale?
        coerce_version(client_version) != coerce_version(server_version)
      end

      def server_version
        controller&.send(:inertia_configuration)&.version
      end

      def coerce_version(version)
        server_version.is_a?(Numeric) ? version.to_f : version
      end

      def force_refresh(request)
        request.flash.keep
        Rack::Response.new('', 409, {'X-Inertia-Location' => request.original_url}).finish
      end

      def copy_xsrf_to_csrf!
        @env['HTTP_X_CSRF_TOKEN'] = @env['HTTP_X_XSRF_TOKEN'] if @env['HTTP_X_XSRF_TOKEN'] && inertia_request?
      end
    end
  end
end
