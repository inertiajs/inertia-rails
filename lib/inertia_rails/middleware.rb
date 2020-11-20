module InertiaRails
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @env = env

      status, headers, body = @app.call(env)
      request = ActionDispatch::Request.new(env)

      ::InertiaRails.reset!

      # Inertia errors are added to the session via redirect_to 
      request.session.delete(:inertia_errors) unless keep_inertia_errors?(status)

      status = 303 if inertia_non_post_redirect?(status)

      return stale_inertia_get? ? force_refresh(request) : [status, headers, body]
    end

    private

    def keep_inertia_errors?(status)
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

    def request_method
      @env['REQUEST_METHOD']
    end

    def inertia_version
      @env['HTTP_X_INERTIA_VERSION']
    end

    def inertia_request?
      @env['HTTP_X_INERTIA'].present?
    end

    def version_stale?
      sent_version != saved_version
    end

    def sent_version
      return nil if inertia_version.nil?
      InertiaRails.version.is_a?(Numeric) ? inertia_version.to_f : inertia_version
    end

    def saved_version
      InertiaRails.version.is_a?(Numeric) ? InertiaRails.version.to_f : InertiaRails.version
    end

    def force_refresh(request)
      request.flash.keep
      Rack::Response.new('', 409, {'X-Inertia-Location' => request.original_url}).finish
    end
  end
end
