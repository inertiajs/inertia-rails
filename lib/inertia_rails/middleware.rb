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
      # 301/302/303 carry a Location we can rewrite into a 409 location response.
      # Method-preserving 307/308 are excluded: a `window.location` visit cannot
      # preserve the original HTTP method.
      CONVERTIBLE_REDIRECT_STATUSES = [301, 302, 303].freeze

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

        # Computed without the `inertia_request?` gate so the plain-client branch
        # below can reuse it to mark the 3xx as varying on `X-Inertia`.
        external_redirect = convertible_external_redirect?(status, headers, request)
        # A converted external redirect behaves like `inertia_location`: the
        # client navigates away, so Inertia session options must not outlive it.
        convert_redirect = external_redirect && inertia_request?

        # Inertia session data is added via redirect_to
        # Guard with session.loaded? to avoid forcing session I/O (and unnecessary
        # database writes) on requests that never accessed the session, e.g. sessionless
        # controllers. If the session was never loaded the Inertia keys cannot have been
        # set, so the cleanup would be a no-op anyway.
        unless (keep_inertia_session_options?(status) && !convert_redirect) || !request.session.loaded?
          request.session.delete(:inertia_errors)
          request.session.delete(:inertia_clear_history)
          request.session.delete(:inertia_preserve_fragment)
        end

        status = 303 if inertia_non_post_redirect?(status)

        if convert_redirect
          convert_to_location_response(headers, body)
        elsif stale_inertia_get?
          force_refresh(request)
        else
          add_inertia_vary!(headers) if external_redirect
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
        (controller&.send(:inertia_configuration) || InertiaRails.configuration).version
      end

      def coerce_version(version)
        server_version.is_a?(Numeric) ? version.to_f : version
      end

      # XHR requests follow redirects transparently, so an Inertia client can
      # never see a redirect to another origin: the follow-up request fails
      # CORS checks. The only redirect mechanism that works cross-origin is
      # the Inertia location response (409 + X-Inertia-Location), which makes
      # the client perform a full `window.location` visit.
      def convertible_external_redirect?(status, headers, request)
        CONVERTIBLE_REDIRECT_STATUSES.include?(status) &&
          convert_external_redirects? &&
          external_origin?(headers['Location'], request)
      end

      def convert_external_redirects?
        (controller&.send(:inertia_configuration) || InertiaRails.configuration).convert_external_redirects
      end

      def external_origin?(location, request)
        return false if location.blank?

        uri = URI.parse(location)
        return false if uri.host.blank?

        scheme = uri.scheme || request.scheme
        port = uri.port || (scheme == 'https' ? 443 : 80)

        scheme != request.scheme || !uri.host.casecmp?(request.host) || port != request.port
      rescue URI::InvalidURIError
        false
      end

      # Mutates the response triple in place to preserve other headers, notably
      # Set-Cookie (which matters mid-OAuth).
      def convert_to_location_response(headers, body)
        headers['X-Inertia-Location'] = headers.delete('Location')
        headers.delete('Content-Type')
        headers.delete('Content-Length')
        body.close if body.respond_to?(:close)

        add_inertia_vary!(headers)
        [409, headers, []]
      end

      # The response varies on the X-Inertia request header (e.g. a 3xx for a
      # plain client vs the converted 409), so a shared cache must not serve one
      # client's variant to the other.
      def add_inertia_vary!(headers)
        existing = headers['Vary']
        headers['Vary'] = existing.blank? ? 'X-Inertia' : "#{existing}, X-Inertia"
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
