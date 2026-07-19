# Instrumentation

Inertia Rails emits [ActiveSupport::Notifications](https://guides.rubyonrails.org/active_support_instrumentation.html) events around rendering, prop resolution, and SSR requests. Subscribe to them to trace rendering with OpenTelemetry or AppSignal, log slow pages, or measure how much time your prop blocks take.

@available_since rails=master

## Events

Events fire on every Inertia render. When no subscribers are attached, the overhead is negligible, so there is nothing to enable or disable.

| Event                         | Wraps                                               | Payload                      |
| ----------------------------- | --------------------------------------------------- | ---------------------------- |
| `render.inertia_rails`        | The entire Inertia render, including view rendering | `:component, :partial, :ssr` |
| `resolve_props.inertia_rails` | Prop resolution, where your prop blocks execute     | `:component, :partial`       |
| `ssr.inertia_rails`           | The HTTP call to the SSR server                     | `:url, :component`           |

The payload keys:

- `:component` — the resolved page component name, such as `"Users/Show"`.
- `:partial` — `true` on [partial reloads](/guide/partial-reloads).
- `:ssr` — `true` when the response body came from [SSR](/guide/server-side-rendering). It stays `false` for JSON responses, when SSR is disabled, and when a failed SSR call falls back to client-side rendering.
- `:url` — the SSR server endpoint the request was sent to.

> [!NOTE]
> A [cached SSR response](/guide/caching#ssr-response-caching) emits no `ssr.inertia_rails` event — the cache read is visible through Rails' own `cache_read.active_support` event instead.

If an instrumented block raises, ActiveSupport records the error in the payload under `:exception` and `:exception_object` before re-raising, so failed SSR calls are observable without any extra configuration.

## Subscribing

Use the standard ActiveSupport API to consume the events:

```ruby
ActiveSupport::Notifications.subscribe('ssr.inertia_rails') do |event|
  Rails.logger.info("SSR render of #{event.payload[:component]} took #{event.duration.round(1)}ms")
end
```

## OpenTelemetry

The [opentelemetry-instrumentation-active_support](https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/active_support) gem converts the events into spans nested inside your request traces:

```ruby
tracer = OpenTelemetry.tracer_provider.tracer('inertia_rails')

%w[render.inertia_rails resolve_props.inertia_rails ssr.inertia_rails].each do |event|
  OpenTelemetry::Instrumentation::ActiveSupport.subscribe(tracer, event)
end
```

Each span carries the payload as attributes, so you can group latency by page component, alert on SSR error rates, or see which SQL queries run inside prop resolution. This is also the path to any backend that ingests OpenTelemetry traces, such as Datadog or Sentry.

## APMs

AppSignal needs no wiring: its [Ruby agent](https://docs.appsignal.com/ruby/instrumentation/instrumentation.html) records ActiveSupport::Notifications events automatically, and they appear in the timeline of each performance sample grouped under `inertia_rails`. New Relic subscribes natively once you list the event names in [`active_support_custom_events_names`](https://docs.newrelic.com/docs/apm/agents/ruby-agent/configuration/ruby-agent-configuration/#active_support_custom_events_names). Other APMs consume the events through the OpenTelemetry setup above or their own tracing APIs.
