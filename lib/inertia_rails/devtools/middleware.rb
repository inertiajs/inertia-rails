# frozen_string_literal: true

module InertiaRails
  module Devtools
    # The outermost DevTools frame. It sits above Rails::Rack::Logger so the
    # extension's polling of the read API can be kept out of the development log,
    # and above ShowExceptions/DebugExceptions so it sees the response they render
    # for a recorded exception, without depending on either being in the stack.
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        return respond(env) unless quiet?(env)

        Rails.logger.silence { respond(env) }
      end

      private

      def respond(env)
        status, headers, body = @app.call(env)
        recorder = env[Recorder::ENV_KEY]

        return [status, headers, body] unless recorder&.exception

        recorder.finish(status, headers, body, error: recorder.exception)
      end

      def quiet?(env)
        return false unless env['PATH_INFO'].to_s.start_with?(ROUTE_PREFIX)
        return false unless Rails.logger.respond_to?(:silence)

        Devtools.swallow { Devtools.enabled? && InertiaRails.configuration.devtools_quiet } || false
      end
    end
  end
end
