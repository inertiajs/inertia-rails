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
require_relative 'devtools/exception_middleware'

module InertiaRails
  module Devtools
    ROUTE_PREFIX = '/_inertia/devtools'
    RENDER_SOURCE_KEY = :__inertia_devtools_render_source
    REPOSITORY_MUTEX = Mutex.new

    class << self
      def enabled?
        InertiaRails.configuration.devtools_enabled?
      end

      def start(env)
        swallow do
          next unless enabled?
          next if skip?(env['PATH_INFO'].to_s)

          env[Recorder::ENV_KEY] = Recorder.new(env)
        end
      end

      def recorder(request)
        request.env[Recorder::ENV_KEY] if request.respond_to?(:env)
      end

      def repository
        config = InertiaRails.configuration
        key = [
          config.devtools_storage_path || Rails.root.join('tmp/inertia-devtools').to_s,
          config.devtools_ttl.to_f,
          config.devtools_prune_interval.to_i
        ]

        REPOSITORY_MUTEX.synchronize do
          unless @repository && @repository_key == key
            @repository = EntriesRepository.new(path: key[0], ttl_hours: key[1], prune_interval: key[2])
            @repository_key = key
          end

          @repository
        end
      end

      def comma_list(value)
        value.to_s.split(',').map(&:strip).reject(&:empty?)
      end

      def swallow
        yield
      rescue StandardError => e
        report(e)
        nil
      end

      def report(error)
        InertiaRails.report_handled_error(error, message: 'DevTools recording failed')
      end

      private

      def skip?(path)
        return true if path.start_with?(ROUTE_PREFIX)

        relative_path = path.delete_prefix('/')
        Array(InertiaRails.configuration.devtools_except).any? do |pattern|
          pattern.is_a?(Regexp) ? pattern.match?(path) : File.fnmatch?(pattern.to_s, relative_path)
        end
      end
    end
  end
end
