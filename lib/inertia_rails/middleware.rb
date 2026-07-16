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
        status, headers, body = if prevent_precognition_writes?
                                  ActiveRecord::Base.while_preventing_writes { @app.call(@env) }
                                else
                                  @app.call(@env)
                                end
        request = ActionDispatch::Request.new(@env)

        conversion = LocationConversion.new(@env, status, headers, request, configuration)
        convert_to_location = inertia_request? && conversion.convertible?

        # Inertia session data is added via redirect_to
        # Guard with session.loaded? to avoid forcing session I/O (and unnecessary
        # database writes) on requests that never accessed the session, e.g. sessionless
        # controllers. If the session was never loaded the Inertia keys cannot have been
        # set, so the cleanup would be a no-op anyway.
        unless (keep_inertia_session_options?(status) && !convert_to_location) || !request.session.loaded?
          request.session.delete(:inertia_errors)
          request.session.delete(:inertia_clear_history)
          request.session.delete(:inertia_preserve_fragment)
        end

        status = 303 if inertia_non_post_redirect?(status)

        if convert_to_location
          conversion.to_response(body)
        elsif stale_inertia_get?
          force_refresh(request)
        else
          [status, headers, body]
        end
      end

      private

      def keep_inertia_session_options?(status)
        redirect_status?(status) || stale_inertia_request?
      end

      def stale_inertia_request?
        inertia_request? && version_stale?
      end

      # Matches Rack::Response::Helpers#redirect? — Inertia session options
      # must survive every redirect until a render consumes them.
      def redirect_status?(status)
        [301, 302, 303, 307, 308].include? status
      end

      # Only 301/302 are rewritten to 303: a 303 already forces a GET on
      # follow, and 307/308 preserve the request method by design.
      def convertible_redirect_status?(status)
        [301, 302].include? status
      end

      def non_get_redirectable_method?
        %w[PUT PATCH DELETE].include? request_method
      end

      def inertia_non_post_redirect?(status)
        inertia_request? && convertible_redirect_status?(status) && non_get_redirectable_method?
      end

      def stale_inertia_get?
        get? && stale_inertia_request?
      end

      def get?
        request_method == 'GET'
      end

      def controller
        @env['action_controller.instance']
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
        configuration.version
      end

      def configuration
        @configuration ||= controller&.send(:inertia_configuration) || InertiaRails.configuration
      end

      def coerce_version(version)
        server_version.is_a?(Numeric) ? version.to_f : version
      end

      def force_refresh(request)
        request.flash.keep
        Rack::Response.new('', 409, { 'X-Inertia-Location' => request.original_url }).finish
      end

      def copy_xsrf_to_csrf!
        @env['HTTP_X_CSRF_TOKEN'] = @env['HTTP_X_XSRF_TOKEN'] if @env['HTTP_X_XSRF_TOKEN']
      end

      def precognition_request?
        @env['HTTP_PRECOGNITION'] == 'true'
      end

      def prevent_precognition_writes?
        precognition_request? &&
          InertiaRails.configuration.precognition_prevent_writes &&
          defined?(ActiveRecord::Base)
      end
    end
  end
end
