# frozen_string_literal: true

require 'rack/body_proxy'

module InertiaRails
  module Devtools
    # Per-request observer. Everything it touches is guarded: a failure here
    # drops the entry, it never changes the response the app produced.
    class Recorder
      ENV_KEY = 'inertia_rails.devtools'
      PREFETCH_HEADERS = %w[HTTP_PURPOSE HTTP_SEC_PURPOSE HTTP_X_MOZ].freeze

      attr_reader :env, :id, :collector

      def initialize(env)
        @env = env
        @id = Ulid.generate
        @started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @collector = nil
        # Shared props are declared in before_actions, so their call sites land
        # here before the render creates a collector.
        @share_sources = {}
        SourceLocator.clear_cache!
      end

      def batch_id
        return unless @env.key?('HTTP_X_INERTIA')

        Headers.read(@env, Headers::PARENT)
      end

      # A prefetch returns its own id so the prefetched page's later requests
      # start their own batch, while still recording under the originating one.
      def outgoing_parent_id
        return @id if prefetch?

        batch_id || @id
      end

      def prefetch?
        PREFETCH_HEADERS.any? { |header| @env[header].to_s.include?('prefetch') }
      end

      def elapsed_ms
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @started_at) * 1000).round(3)
      end

      def render_started(component:, render_source:, shared_keys:)
        Devtools.swallow do
          @collector = Collector.new(
            component: component,
            render_source: render_source,
            share_sources: @share_sources
          )
          @collector.shared_keys = shared_keys
        end
      end

      def share_source(keys, source)
        return unless source

        Devtools.swallow do
          keys.each { |key| @share_sources[key.to_s] ||= SourceLocator.refine(source, key) }
        end
      end

      def prop_resolved(path, prop, rescued: false)
        return unless @collector

        Devtools.swallow do
          @collector.add_prop(path, classifier.classify(path, prop), rescued: rescued)
        end
      end

      def page_rendered(page)
        return unless @collector

        @collector.page = page
      end

      def finish(status, headers, body)
        headers[Headers::ID] = @id
        headers[Headers::PARENT_OUT] = outgoing_parent_id

        entry = Devtools.swallow { EntryBuilder.new(self, status: status, headers: headers, body: body).build }
        return [status, headers, body] unless entry

        [status, headers, Rack::BodyProxy.new(body) { persist(entry) }]
      end

      private

      def persist(entry)
        config = InertiaRails.configuration
        repository = Devtools.repository

        repository.record(
          @id,
          Redaction.redact_payload(entry),
          tab_uuid: Headers.read(@env, Headers::TAB),
          limit: config.devtools_limit.to_i
        )
        repository.prune_if_due
      end

      def classifier
        @classifier ||= PropClassifier.new(
          deferred_request: !Headers.read(@env, Headers::DEFERRED).nil?,
          reset_keys: @env['HTTP_X_INERTIA_RESET'].to_s.split(',').map(&:strip).reject(&:empty?)
        )
      end
    end
  end
end
