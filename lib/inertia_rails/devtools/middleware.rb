# frozen_string_literal: true

module InertiaRails
  module Devtools
    # The outermost DevTools frame: above Rails::Rack::Logger so read API polling can
    # be kept out of the log, and above ShowExceptions/DebugExceptions so it sees the
    # response they render for a recorded exception without depending on either.
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        return respond(env) unless silence_logs?(env)

        Rails.logger.silence { respond(env) }
      end

      private

      def respond(env)
        status, headers, body = @app.call(env)
        recorder = env[Recorder::ENV_KEY]

        return [status, headers, body] unless recorder&.exception

        recorder.finish(status, headers, body, error: recorder.exception)
      end

      def silence_logs?(env)
        return false unless env['PATH_INFO'].to_s.start_with?(ROUTE_PREFIX)
        return false unless Rails.logger.respond_to?(:silence)

        Devtools.swallow { Devtools.enabled? && InertiaRails.configuration.devtools_silence_logs } || false
      end
    end
  end
end
