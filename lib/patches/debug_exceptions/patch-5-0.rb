# Patch ActionDispatch::DebugExceptions to render HTML for Inertia requests
#
# Original source:
# https://github.com/rails/rails/blob/5-0-stable/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
#

module InertiaRails
  module InertiaDebugExceptions
    def render_for_default_application(request, wrapper)
      template = create_template(request, wrapper)
      file = "rescues/#{wrapper.rescue_template}"

      if request.xhr? && !request.headers['X-Inertia'] # <<<< this line is changed only
        body = template.render(template: file, layout: false, formats: [:text])
        format = "text/plain"
      else
        body = template.render(template: file, layout: 'rescues/layout')
        format = "text/html"
      end
      render(wrapper.status_code, body, format)
    end
  end
end

if defined?(ActionDispatch::DebugExceptions)
  ActionDispatch::DebugExceptions.prepend InertiaRails::InertiaDebugExceptions
end
