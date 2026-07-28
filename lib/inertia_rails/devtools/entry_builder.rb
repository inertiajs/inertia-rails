# frozen_string_literal: true

module InertiaRails
  module Devtools
    # Turns a finished request/response pair plus the render collector into the
    # entry envelope the DevTools extension reads.
    class EntryBuilder
      RAW_BODY_LIMIT = 256_000
      WRITE_METHODS = %w[POST PUT PATCH DELETE].freeze
      TEXTUAL_CONTENT_TYPES = %w[json text/ xml javascript].freeze

      def initialize(recorder, status:, headers:, body:)
        @recorder = recorder
        @env = recorder.env
        @request = ActionDispatch::Request.new(@env)
        @status = status
        @headers = headers
        @body = body
        @collector = recorder.collector
      end

      def build
        {
          __meta: meta,
          http: {
            requestHeaders: Redaction.redact_headers(request_headers),
            responseHeaders: Redaction.redact_headers(@headers.to_h),
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
          timestamp: Time.at(utime).utc.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
          utime: utime,
          method: @request.request_method,
          url: @request.original_url,
          component: @collector&.component,
          requestType: request_type,
          status: @status,
          redirectLocation: redirect_location,
          serverTimingMs: @recorder.elapsed_ms,
          visitId: Headers.read(@env, Headers::VISIT),
        }
      end

      def page_payload
        {
          props: payload[:props] || {},
          propValues: payload[:propValues] || {},
          route: RouteLocator.resolve(@request),
          renderSource: payload[:renderSource],
          componentPath: payload[:componentPath],
        }.compact
      end

      def payload
        @payload ||= @collector&.build || {}
      end

      # Order is significant: `deferred` and `poll` are client-declared, because
      # they are indistinguishable from a partial reload on the wire.
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

      def header(name)
        @downcased_headers ||= @headers.to_h.transform_keys { |key| key.to_s.downcase }
        value = @downcased_headers[name]
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

        body_string(@request.raw_post)
      rescue StandardError
        omitted('unserializable')
      end

      def response_body
        return raw_response_body unless @collector

        page = payload[:responseBody]
        page.nil? ? { status: 'empty' } : body_value(Redaction.redact(page))
      end

      def raw_response_body
        content_type = header('content-type').to_s.downcase
        return omitted('non-textual') unless TEXTUAL_CONTENT_TYPES.any? { |needle| content_type.include?(needle) }

        content = response_content
        return omitted('streamed') if content.nil?
        return { status: 'empty' } if content.empty?
        return omitted('too-large') if content.bytesize > RAW_BODY_LIMIT

        if content_type.include?('json')
          decoded = JSON.parse(content)
          return body_value(Redaction.redact(decoded)) if decoded.is_a?(Hash) || decoded.is_a?(Array)
        end

        body_string(content)
      rescue JSON::ParserError
        body_string(response_content)
      end

      # `to_ary` is the Rack contract for a fully buffered body; a streaming body
      # only responds to `each`, and draining it here would deliver it to nobody.
      def response_content
        @body.to_ary.join if @body.respond_to?(:to_ary)
      end

      def body_value(value)
        { status: 'present', value: Redaction.sanitize(value) }
      end

      def body_string(content)
        return { status: 'empty' } if content.nil? || content.empty?

        text = content.dup.force_encoding(Encoding::UTF_8)
        return omitted('binary') unless text.valid_encoding?

        { status: 'present', value: text }
      end

      def omitted(reason)
        { status: 'omitted', reason: reason }
      end

      def summarize_uploads(value)
        case value
        when Hash then value.transform_values { |nested| summarize_uploads(nested) }
        when Array then value.map { |item| summarize_uploads(item) }
        when ActionDispatch::Http::UploadedFile
          { name: value.original_filename, size: value.size, mimeType: value.content_type }
        else value
        end
      end
    end
  end
end
