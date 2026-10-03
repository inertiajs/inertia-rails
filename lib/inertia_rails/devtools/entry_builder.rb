# frozen_string_literal: true

module InertiaRails
  module Devtools
    class EntryBuilder
      CGI_HEADERS = %w[CONTENT_TYPE CONTENT_LENGTH].freeze
      NO_PAGE = { props: {}, propValues: {}, renderSource: nil, componentPath: nil }.freeze

      def initialize(recorder, status:, headers:)
        @recorder = recorder
        @request = recorder.request
        @status = status
        @headers = headers
        @collector = recorder.collector
        @bodies = BodyCapture.new(@request, controller: recorder.controller)
      end

      def build
        {
          __meta: meta,
          http: {
            requestHeaders: Redaction.redact_headers(request_headers),
            responseHeaders: response_headers,
            requestBody: @bodies.request_body,
            responseBody: response_body,
          },
          route: RouteLocator.resolve(@request, @recorder.controller),
        }.merge(@collector&.build || NO_PAGE)
      end

      private

      def meta
        now = Time.now.utc

        {
          id: @recorder.id,
          tabUuid: @recorder.tab_uuid,
          batchId: @recorder.batch_id,
          timestamp: now.iso8601(3),
          utime: now.to_f,
          method: @request.request_method,
          url: Redaction.redact_url(@request.original_url),
          component: @collector&.component,
          requestType: request_type,
          status: @status,
          redirectLocation: redirect_location,
          serverTimingMs: @recorder.elapsed_ms,
          visitId: @recorder.visit_id,
        }
      end

      def request_type
        return 'precognition' if @request.inertia_precognitive?
        return @collector ? 'initial' : 'http' unless @request.inertia?
        return 'deferred' if @recorder.deferred?
        return 'poll' if @recorder.poll?
        return 'partial' if @request.inertia_partial?
        return 'prefetch' if @recorder.prefetch?

        'navigate'
      end

      def response_body
        @bodies.response_body(
          status: @status, content_type: header('content-type').to_s.downcase, page: @collector&.stored_page
        )
      end

      def redirect_location
        response_headers['x-inertia-location'].presence ||
          (response_headers['location'].presence if (300..399).cover?(@status))
      end

      def response_headers
        @response_headers ||= Redaction.redact_headers(downcased_headers)
      end

      def request_headers
        @request.env.each_with_object({}) do |(key, value), headers|
          next unless value.is_a?(String) && (key.start_with?('HTTP_') || CGI_HEADERS.include?(key))

          headers[key.delete_prefix('HTTP_').downcase.tr('_', '-')] = value
        end
      end

      # Rack 2 keeps header names capitalized.
      def downcased_headers
        @downcased_headers ||= @headers.to_h.transform_keys { |key| key.to_s.downcase }
      end

      def header(name)
        Array(downcased_headers[name]).first
      end
    end
  end
end
