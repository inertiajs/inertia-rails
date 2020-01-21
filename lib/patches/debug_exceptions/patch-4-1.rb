# Patch ActionDispatch::DebugExceptions to render HTML for Inertia requests
#
# Original source:
# https://github.com/rails/rails/blob/4-1-stable/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
#

ActionDispatch::DebugExceptions.class_eval do
  prepend(InertiaDebugExceptions = Module.new do
    def render_exception(env, exception)
      wrapper = ExceptionWrapper.new(env, exception)
      log_error(env, wrapper)

      if env['action_dispatch.show_detailed_exceptions']
        request = Request.new(env)
        template = ActionView::Base.new([RESCUES_TEMPLATE_PATH],
          request: request,
          exception: wrapper.exception,
          application_trace: wrapper.application_trace,
          framework_trace: wrapper.framework_trace,
          full_trace: wrapper.full_trace,
          routes_inspector: routes_inspector(exception),
          source_extract: wrapper.source_extract,
          line_number: wrapper.line_number,
          file: wrapper.file
        )
        file = "rescues/#{wrapper.rescue_template}"

        if request.xhr? && !request.headers['X-Inertia'] # <<<< this line is changed only
          body = template.render(template: file, layout: false, formats: [:text])
          format = "text/plain"
        else
          body = template.render(template: file, layout: 'rescues/layout')
          format = "text/html"
        end
        render(wrapper.status_code, body, format)
      else
        raise exception
      end
    end
  end)
end
