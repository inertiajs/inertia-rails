# Patch ActionDispatch::DebugExceptions to render HTML for Inertia requests
#
# Original source:
# https://github.com/rails/rails/blob/v6.0.1/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
#
module ActionDispatch
  class DebugExceptions
    private

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
  end
end
