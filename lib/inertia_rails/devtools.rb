# frozen_string_literal: true

require_relative 'devtools/config'
require_relative 'devtools/redaction'
require_relative 'devtools/source_locator'
require_relative 'devtools/prop_classifier'
require_relative 'devtools/route_locator'
require_relative 'devtools/collector'
require_relative 'devtools/body_capture'
require_relative 'devtools/entry_builder'
require_relative 'devtools/entry_store'
require_relative 'devtools/recorder'
require_relative 'devtools/middleware'

module InertiaRails
  module Devtools
    ROUTE_PREFIX = '/_inertia/devtools'

    class << self
      def config
        @config ||= Config.new
      end

      def enabled?
        config.enabled?
      end

      def recorder(request)
        request.env[Recorder::ENV_KEY]
      end

      def store
        @store ||= EntryStore.new
      end

      def swallow
        yield
      rescue StandardError => e
        report(e)
        nil
      end

      def report(error)
        if Rails.respond_to?(:error)
          Rails.error.report(error, handled: true)
        else
          Rails.logger&.error("[inertia-rails] DevTools recording failed: #{error.class}: #{error.message}")
        end
      end
    end
  end
end
