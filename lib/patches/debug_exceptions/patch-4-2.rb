# Patch ActionDispatch::DebugExceptions to render HTML for Inertia requests
#
# Original source:
# https://github.com/rails/rails/blob/4-2-stable/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb
#

ActionDispatch::DebugExceptions.class_eval do
  prepend(InertiaDebugExceptions = Module.new do
    def render_exception(env, exception)
      wrapper = ExceptionWrapper.new(env, exception)
      log_error(env, wrapper)

      if env['action_dispatch.show_detailed_exceptions']
        request = Request.new(env)
        traces = wrapper.traces

        trace_to_show = 'Application Trace'
        if traces[trace_to_show].empty? && wrapper.rescue_template != 'routing_error'
          trace_to_show = 'Full Trace'
        end

        if source_to_show = traces[trace_to_show].first
          source_to_show_id = source_to_show[:id]
        end

        template = ActionView::Base.new([RESCUES_TEMPLATE_PATH],
          request: request,
          exception: wrapper.exception,
          traces: traces,
          show_source_idx: source_to_show_id,
          trace_to_show: trace_to_show,
          routes_inspector: routes_inspector(exception),
          source_extracts: wrapper.source_extracts,
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
