# frozen_string_literal: true

require_relative 'devtools/ulid'
require_relative 'devtools/headers'
require_relative 'devtools/redaction'
require_relative 'devtools/source_locator'
require_relative 'devtools/prop_classifier'
require_relative 'devtools/route_locator'
require_relative 'devtools/component_path_locator'
require_relative 'devtools/collector'
require_relative 'devtools/entry_builder'
require_relative 'devtools/entries_repository'
require_relative 'devtools/recorder'

module InertiaRails
  # Server-side half of the Inertia DevTools protocol.
  #
  # https://inertiajs.com/docs/v3/advanced/devtools-protocol
  module Devtools
    ROUTE_PREFIX = '/_inertia/devtools'

    class << self
      # Enablement is global: the read API routes are drawn once, so a per-controller
      # override could advertise entries the API refuses to serve.
      def enabled?
        InertiaRails.configuration.devtools_enabled?
      end

      def start(env)
        return unless enabled?
        return if skip?(env['PATH_INFO'].to_s)

        env[Recorder::ENV_KEY] = Recorder.new(env)
      end

      # Returns the recorder for the request in flight, or nil when devtools is off.
      # The env key only exists once `start` has run, so this needs no config read.
      def recorder(request)
        request.env[Recorder::ENV_KEY] if request.respond_to?(:env)
      end

      # Rebuilt whenever the storage options change; otherwise reused so the
      # write-failure circuit breaker survives across requests.
      def repository
        config = InertiaRails.configuration
        key = [
          config.devtools_storage_path || Rails.root.join('tmp/inertia-devtools').to_s,
          config.devtools_ttl.to_i,
          config.devtools_prune_interval.to_i
        ]
        return @repository if @repository_key == key

        @repository_key = key
        @repository = EntriesRepository.new(path: key[0], ttl_hours: key[1], prune_interval: key[2])
      end

      # Recording is a passive observer: a malformed request, an unserializable prop,
      # or a misconfigured redact list must never turn the app's response into a 500.
      def swallow
        yield
      rescue StandardError => e
        report(e)
        nil
      end

      def report(error)
        if Rails.respond_to?(:error)
          Rails.error.report(error, handled: true, source: 'inertia_rails.devtools')
        else
          Rails.logger&.warn("[inertia-rails] DevTools recording failed: #{error.class}: #{error.message}")
        end
      end

      private

      def skip?(path)
        return true if path.start_with?(ROUTE_PREFIX)

        Array(InertiaRails.configuration.devtools_except).any? do |pattern|
          pattern.is_a?(Regexp) ? pattern.match?(path) : File.fnmatch?(pattern.to_s, path)
        end
      end
    end
  end
end
