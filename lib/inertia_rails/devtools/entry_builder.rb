# frozen_string_literal: true

module InertiaRails
  module Devtools
    class EntryBuilder
      RAW_BODY_LIMIT = 256_000
      WRITE_METHODS = %w[POST PUT PATCH DELETE].freeze
      TEXTUAL_CONTENT_TYPES = %w[json text/ xml javascript].freeze

      def initialize(recorder, status:, headers:, body:, error: nil)
        @recorder = recorder
        @env = recorder.env
        @request = ActionDispatch::Request.new(@env)
        @status = status
        @headers = headers
        @body = body
        @error = error
        @collector = recorder.collector
      end

      def build
        {
          __meta: meta,
          http: {
            requestHeaders: Redaction.redact_headers(request_headers),
            responseHeaders: Redaction.redact_headers(downcased_headers),
            requestBody: request_body,
            responseBody: response_body,
          },
        }.merge(page_payload)
      end

      private

      def meta
        utime = Time.now.to_f

        {
          id: @recorder.id,
          tabUuid: Headers.read(@env, Headers::TAB),
          batchId: @recorder.batch_id,
          timestamp: Time.at(utime).utc.iso8601(3),
          utime: utime,
          method: @request.request_method,
          url: @request.original_url,
          component: @collector&.component,
          requestType: request_type,
          status: @status,
          redirectLocation: redirect_location,
          serverTimingMs: @recorder.elapsed_ms,
          visitId: Headers.read(@env, Headers::VISIT),
        }.tap do |entry|
          entry[:error] = { class: @error.class.name, message: @error.message.to_s } if @error
        end
      end

      def page_payload
        {
          props: payload[:props] || {},
          propValues: payload[:propValues] || {},
          route: RouteLocator.resolve(@request) || { name: nil, uri: '', action: nil },
          renderSource: payload[:renderSource],
          componentPath: payload[:componentPath],
        }
      end

      def payload
        @payload ||= @collector&.build || {}
      end

      def request_type
        return 'precognition' if @env['HTTP_PRECOGNITION']
        return @collector ? 'initial' : 'http' unless @request.inertia?
        return 'deferred' if Headers.read(@env, Headers::DEFERRED)
        return 'poll' if Headers.read(@env, Headers::POLL)
        return 'partial' if @env['HTTP_X_INERTIA_PARTIAL_COMPONENT']
        return 'prefetch' if @recorder.prefetch?

        'navigate'
      end

      def redirect_location
        location = header('x-inertia-location')
        return location if location.present?
        return unless (300...400).cover?(@status)

        header('location').presence
      end

      # Downcased for lookups and storage — Rack 2 capitalizes response header
      # names, Rack 3 requires them lowercase.
      def downcased_headers
        @downcased_headers ||= @headers.to_h.transform_keys { |key| key.to_s.downcase }
      end

      def header(name)
        value = downcased_headers[name]
        value.is_a?(Array) ? value.first : value
      end

      def request_headers
        @env.each_with_object({}) do |(key, value), headers|
          next unless value.is_a?(String)

          if key.start_with?('HTTP_')
            headers[key.delete_prefix('HTTP_').downcase.tr('_', '-')] = value
          elsif %w[CONTENT_TYPE CONTENT_LENGTH].include?(key)
            headers[key.downcase.tr('_', '-')] = value
          end
        end
      end

      def request_body
        return omitted('non-inertia-request') if WRITE_METHODS.include?(@request.request_method) && !@request.inertia?

        parameters = @request.request_parameters
        return body_value(Redaction.redact(summarize_uploads(parameters))) if parameters.present?

        raw_request_body
      rescue StandardError
        omitted('unserializable')
      end

      # Unparsed bodies must be structured JSON to be safely redacted.
      def raw_request_body
        content = @request.raw_post
        return { status: 'empty' } if content.nil? || content.empty?
        return omitted('too-large') if content.bytesize > RAW_BODY_LIMIT

        decoded = JSON.parse(content)
        return omitted('unredactable') unless decoded.is_a?(Hash) || decoded.is_a?(Array)

        body_value(Redaction.redact(decoded))
      rescue JSON::ParserError
        omitted('unredactable')
      end

      def response_body
        return omitted('exception') if @error
        return raw_response_body unless @collector

        page = payload[:responseBody]
        return { status: 'empty' } if page.nil?

        body_value(Redaction.redact(page))
      end

      # Unparsed bodies must be structured JSON to be safely redacted — an HTML page
      # or a text blob can embed a CSRF token or a secret under no key we can match.
      def raw_response_body
        content_type = header('content-type').to_s.downcase
        return omitted('non-textual') unless TEXTUAL_CONTENT_TYPES.any? { |needle| content_type.include?(needle) }

        content = response_content
        return omitted('streamed') if content.nil?
        return { status: 'empty' } if content.empty?
        return omitted('too-large') if content.bytesize > RAW_BODY_LIMIT
        return omitted('unredactable') unless content_type.include?('json')

        decoded = JSON.parse(content)
        return omitted('unredactable') unless decoded.is_a?(Hash) || decoded.is_a?(Array)

        body_value(Redaction.redact(decoded))
      rescue JSON::ParserError
        omitted('unredactable')
      end

      # Do not drain streaming Rack bodies.
      def response_content
        Devtools.buffered_body(@env, @body)
      end

      def body_value(value)
        { status: 'present', value: value }
      end

      def omitted(reason)
        { status: 'omitted', reason: reason }
      end

      def summarize_uploads(parameters)
        parameters.deep_transform_values do |value|
          if value.is_a?(ActionDispatch::Http::UploadedFile)
            { name: value.original_filename, size: value.size, mimeType: value.content_type }
          else
            value
          end
        end
      end
    end
  end
end
