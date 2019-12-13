# Patch ActionDispatch::DebugExceptions to render HTML for Inertia requests
#
# Original source (unchanged since Rails 5.1):
# https://github.com/rails/rails/blob/5-1-stable/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
# https://github.com/rails/rails/blob/5-2-stable/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
# https://github.com/rails/rails/blob/6-0-stable/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
#

ActionDispatch::DebugExceptions.class_eval do
  prepend(InertiaDebugExceptions = Module.new do
    def render_for_browser_request(request, wrapper)
      template = create_template(request, wrapper)
      file = "rescues/#{wrapper.rescue_template}"

      if request.xhr? && !request.headers['X-Inertia'] # <<<< this line is changed only
        body = template.render(template: file, layout: false, formats: [:text])
        format = "text/plain"
      else
        body = template.render(template: file, layout: "rescues/layout")
        format = "text/html"
      end

      render(wrapper.status_code, body, format)
    end
  end)
end
