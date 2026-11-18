# frozen_string_literal: true

module InertiaRails
  module Devtools
    class Recorder
      ENV_KEY = 'inertia_rails.devtools'
      PREFETCH_HEADERS = %w[Purpose Sec-Purpose X-Moz].freeze

      attr_reader :request, :id

      def initialize(env)
        @request = ActionDispatch::Request.new(env)
        @id = EntryStore.generate_id
        @started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @collector = nil
        @share_sources = {}
        @prop_sources = {}
        # Keyed by object, so identical hashes shared in different places keep their own links.
        @share_declarations = {}.compare_by_identity
        # Read now: Rails changes it while routing into a mounted engine.
        @base_path = env['SCRIPT_NAME'].chomp('/').presence
      end

      # Runs the app with this recorder in reach of the hooks, then stamps and saves the entry.
      def record
        @request.env[ENV_KEY] = self
        status, headers, body = yield
        finish(status, headers)
        [status, headers, body]
      end

      # Runs after the controller's filters, so `current_user` is already set.
      def authorized?
        return @authorized if defined?(@authorized)

        @authorized = !!Devtools.swallow { Devtools.config.allows?(controller) }
      end

      def discovery_tag
        return unless collector

        ActionController::Base.helpers.tag.script(
          @id.to_json.html_safe,
          data: { inertia_devtools_id: '', inertia_devtools_base_path: @base_path }, type: 'application/json'
        )
      end

      def render_started(component:, render_source:, shared_keys:)
        @collector = Collector.new(
          component: component,
          render_source: render_source,
          share_sources: @share_sources,
          prop_sources: @prop_sources,
          shared_keys: shared_keys
        )
      end

      def prop_resolved(path, prop, reset: false)
        @collector.add_prop(path, classifier.classify(prop), reset: reset)
      end

      # A serializer may say where it declared each prop, as `[file, line]` pairs keyed like its `to_inertia`.
      def serializer_found(serializer, path = nil)
        return unless serializer.respond_to?(:inertia_prop_sources)

        Devtools.swallow do
          serializer.inertia_prop_sources.each do |key, (file, line)|
            @prop_sources[[path, key].compact.join('.')] = { file: file, line: line } if file
          end
        end
      end

      def page_rendered(page)
        @collector.page = page
      end

      # Remembers where an `inertia_share` hash was written.
      def share_declared(data, source)
        @share_declarations[data] = source if source
      end

      # Called in merge order, so a key shared twice links to the share that wins.
      def share_resolved(data, result)
        return unless result.is_a?(Hash) && authorized?

        source = data.respond_to?(:call) ? SourceLocator.block_source(data) : @share_declarations[data]
        keys = result.keys.map(&:to_s)
        @share_sources.merge!(source ? SourceLocator.key_sources(source, keys) : keys.index_with(nil))
      end

      def collector
        @collector if @collector&.page
      end

      def controller
        @request.env['action_controller.instance']
      end

      def elapsed_ms
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @started_at) * 1000).round(3)
      end

      def batch_id
        return unless @request.inertia?

        @request.headers['X-Inertia-Devtools-Parent'].presence
      end

      def tab_uuid
        @request.headers['X-Inertia-Devtools-Tab'].presence
      end

      def visit_id
        @request.headers['X-Inertia-Devtools-Visit'].presence
      end

      def deferred?
        @request.headers['X-Inertia-Devtools-Deferred'].present?
      end

      def poll?
        @request.headers['X-Inertia-Devtools-Poll'].present?
      end

      def prefetch?
        PREFETCH_HEADERS.any? { |header| @request.headers[header].to_s.downcase.include?('prefetch') }
      end

      private

      def finish(status, headers)
        # A plain Rack app may return frozen headers.
        return if headers.frozen? || !authorized?

        headers['x-inertia-devtools-id'] = @id
        headers['x-inertia-devtools-parent-out'] = outgoing_parent_id
        headers['x-inertia-devtools-base-path'] = @base_path if @base_path

        # Saved before the response goes out: the extension asks for it as soon as it sees the headers.
        Devtools.swallow do
          entry = EntryBuilder.new(self, status: status, headers: headers).build
          Devtools.store.write(@id, entry, tab_uuid: tab_uuid)
        end
      end

      def outgoing_parent_id
        return @id if prefetch?

        batch_id || @id
      end

      def classifier
        @classifier ||= PropClassifier.new(deferred_request: deferred?)
      end
    end
  end
end
