module InertiaRails
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      request = ActionDispatch::Request.new(env)

      ::InertiaRails.reset!

      # Inertia errors are added to the session via redirect_to
      request.session.delete(:inertia_errors) unless keep_inertia_errors?(status, env)

      status = 303 if inertia_non_post_redirect?(status, env)

      return stale_inertia_get?(env) ? force_refresh(request) : [status, headers, body]
    end

    private

    def keep_inertia_errors?(status, env)
      redirect_status?(status) || stale_inertia_request?(env)
    end

    def stale_inertia_request?(env)
      inertia_request?(env) && version_stale?(env)
    end

    def redirect_status?(status)
      [301, 302].include? status
    end

    def non_get_redirectable_method?(env)
      ["PUT", "PATCH", "DELETE"].include? request_method(env)
    end

    def inertia_non_post_redirect?(status, env)
      inertia_request?(env) && redirect_status?(status) && non_get_redirectable_method?(env)
    end

    def stale_inertia_get?(env)
      get?(env) && stale_inertia_request?(env)
    end

    def get?(env)
      request_method(env) == "GET"
    end

    def request_method(env)
      env["REQUEST_METHOD"]
    end

    def inertia_version(env)
      env["HTTP_X_INERTIA_VERSION"]
    end

    def inertia_request?(env)
      env["HTTP_X_INERTIA"].present?
    end

    def version_stale?(env)
      sent_version(env) != saved_version
    end

    def sent_version(env)
      return nil if inertia_version(env).nil?

      InertiaRails.version.is_a?(Numeric) ? inertia_version(env).to_f : inertia_version(env)
    end

    def saved_version
      InertiaRails.version.is_a?(Numeric) ? InertiaRails.version.to_f : InertiaRails.version
    end

    def force_refresh(request)
      request.flash.keep
      Rack::Response.new("", 409, { "X-Inertia-Location" => request.original_url }).finish
    end
  end
end
