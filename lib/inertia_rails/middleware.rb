module InertiaRails
  class Middleware
    def initialize(app)
      @app = app
    end
  
    def call(env)
      status, headers, body = @app.call(env)
      request = ActionDispatch::Request.new(env)
  
      return [status, headers, body] unless env['HTTP_X_INERTIA'].present?
  
      return force_refresh(request) if stale?(env['REQUEST_METHOD'], env['HTTP_X_INERTIA_VERSION'])
  
      if is_redirect_status?(status) &&
          is_non_get_redirectable_method?(env['REQUEST_METHOD'])
        status = 303
      end
  
      [status, headers, body]
    end
  
    private
  
    def is_redirect_status?(status)
      [301, 302].include? status
    end
  
    def is_non_get_redirectable_method?(request_method)
      ['PUT', 'PATCH', 'DELETE'].include? request_method
    end
  
    def stale?(request_method, inertia_version)
      sent_version = InertiaRails.version.is_a?(Numeric) ? inertia_version.to_f : inertia_version
      saved_version = InertiaRails.version.is_a?(Numeric) ? InertiaRails.version.to_f : InertiaRails.version
      request_method == 'GET' && sent_version != saved_version
    end
  
    def force_refresh(request)
      request.flash.keep
      Rack::Response.new('', 409, {'X-Inertia-Location' => request.original_url})
    end
  end
end
