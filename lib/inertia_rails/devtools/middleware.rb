# frozen_string_literal: true

module InertiaRails
  module Devtools
    # Runs before Rails logs the request and handles errors, so entries get the final status
    # and error page, and the extension's own requests stay out of the log.
    class Middleware
      # Sec-Fetch-Dest values worth recording; "empty" means fetch/XHR.
      RECORDED_DESTINATIONS = %w[document empty frame iframe].freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless Devtools.enabled?
        return Rails.logger.silence { @app.call(env) } if read_api?(env)
        return @app.call(env) if subresource?(env) || skipped?(env['PATH_INFO'])

        Recorder.new(env).record { @app.call(env) }
      end

      private

      def read_api?(env)
        env['PATH_INFO'].start_with?("#{ROUTE_PREFIX}/")
      end

      def subresource?(env)
        destination = env['HTTP_SEC_FETCH_DEST']
        destination && !RECORDED_DESTINATIONS.include?(destination)
      end

      def skipped?(path)
        relative_path = path.delete_prefix('/')

        Array(Devtools.config.except).any? do |pattern|
          pattern.is_a?(Regexp) ? pattern.match?(path) : File.fnmatch?(pattern.to_s, relative_path)
        end
      end
    end
  end
end
