# frozen_string_literal: true

# Patch ActionDispatch::DebugExceptions to render HTML for Inertia requests
#
# The original source needs to be patched, so that Inertia requests are
# NOT responded with plain text, but with HTML.
#
# Original source:
# https://github.com/rails/rails/blob/8-0-stable/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
# https://github.com/rails/rails/blob/main/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
#

module InertiaRails
  module InertiaDebugExceptions
    # Rails 8.2+ passes content_type as third argument
    def render_for_browser_request(request, wrapper, content_type = nil)
      template = create_template(request, wrapper)
      file = "rescues/#{wrapper.rescue_template}"

      if content_type == Mime[:md]
        body = template.render(template: file, layout: false, formats: [:text])
        format = 'text/markdown'
      elsif request.xhr? && !request.headers['X-Inertia']
        body = template.render(template: file, layout: false, formats: [:text])
        format = 'text/plain'
      else
        body = template.render(template: file, layout: 'rescues/layout')
        format = 'text/html'
      end

      render(wrapper.status_code, body, format)
    end
  end
end

if defined?(ActionDispatch::DebugExceptions)
  ActionDispatch::DebugExceptions.prepend InertiaRails::InertiaDebugExceptions
end
