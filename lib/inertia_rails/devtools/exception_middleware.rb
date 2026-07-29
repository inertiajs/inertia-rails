# frozen_string_literal: true

module InertiaRails
  module Devtools
    class ExceptionMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)
        recorder = env[Recorder::ENV_KEY]

        return [status, headers, body] unless recorder&.exception

        recorder.finish(status, headers, body, error: recorder.exception)
      end
    end
  end
end
