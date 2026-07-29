# frozen_string_literal: true

require 'rack/body_proxy'

module InertiaRails
  module Devtools
    class Recorder
      ENV_KEY = 'inertia_rails.devtools'
      PREFETCH_HEADERS = %w[HTTP_PURPOSE HTTP_SEC_PURPOSE HTTP_X_MOZ].freeze

      attr_reader :env, :id, :collector, :exception

      def initialize(env)
        @env = env
        @id = Ulid.generate
        @started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @collector = nil
        @share_sources = {}
      end

      def batch_id
        return unless @env.key?('HTTP_X_INERTIA')

        Headers.read(@env, Headers::PARENT)
      end

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
            share_sources: @share_sources,
            shared_keys: shared_keys
          )
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

      def finish(status, headers, body, error: nil)
        Devtools.swallow do
          id_key, parent_key = Headers.response_keys
          headers[id_key] = @id
          headers[parent_key] = outgoing_parent_id
        end

        body = inject_devtools_tag(status, headers, body)

        entry = Devtools.swallow do
          EntryBuilder.new(self, status: status, headers: headers, body: body, error: error).build
        end

        return [status, headers, body] unless entry

        [status, headers, Rack::BodyProxy.new(body) { persist(entry) }]
      end

      def record_exception(error)
        @exception = error

        entry = Devtools.swallow do
          EntryBuilder.new(self, status: 500, headers: {}, body: nil, error: error).build
        end

        persist(entry) if entry
      end

      private

      def inject_devtools_tag(status, headers, body)
        Devtools.swallow do
          next body unless status == 200 && @collector
          next body if @env.key?('HTTP_X_INERTIA')
          next body unless header_value(headers, 'content-type').to_s.include?('text/html')

          content = Devtools.buffered_body(@env, body)
          next body unless content

          insert_at = content.rindex(%r{</body\s*>}i) || content.length
          content.insert(insert_at, devtools_tag)

          replace_content_length(headers, content)
          body.close if body.respond_to?(:close)
          [content]
        end || body
      end

      def devtools_tag
        attributes = 'data-inertia-devtools-id="" type="application/json"'
        nonce = content_security_policy_nonce
        attributes = %(#{attributes} nonce="#{nonce}") if nonce

        %(<script #{attributes}>#{@id.to_json}</script>)
      end

      def content_security_policy_nonce
        request = ActionDispatch::Request.new(@env)
        request.content_security_policy_nonce if request.respond_to?(:content_security_policy_nonce)
      end

      def header_value(headers, name)
        key = headers.keys.find { |candidate| candidate.to_s.casecmp(name).zero? }
        key && headers[key]
      end

      def replace_content_length(headers, content)
        key = headers.keys.find { |candidate| candidate.to_s.casecmp('content-length').zero? }
        headers[key] = content.bytesize.to_s if key
      end

      def persist(entry)
        Devtools.swallow do
          config = InertiaRails.configuration
          repository = Devtools.repository

          repository.record(
            @id,
            Redaction.redact_payload(entry),
            tab_uuid: Headers.read(@env, Headers::TAB),
            limit: config.devtools_limit.to_i,
            max_entries: config.devtools_max_entries.to_i
          )

          repository.prune_if_due
        end
      end

      def classifier
        @classifier ||= PropClassifier.new(
          deferred_request: !Headers.read(@env, Headers::DEFERRED).nil?,
          reset_keys: Devtools.comma_list(@env['HTTP_X_INERTIA_RESET'])
        )
      end
    end
  end
end
