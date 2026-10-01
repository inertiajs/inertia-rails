# frozen_string_literal: true

module InertiaRails
  module Devtools
    # What an entry stores for the request and response bodies: empty, present, or omitted
    # with a reason the extension shows.
    class BodyCapture
      RAW_BODY_LIMIT = 256_000
      WRITE_METHODS = %w[POST PUT PATCH DELETE].freeze
      TEXTUAL_CONTENT_TYPES = %w[json text/ xml javascript].freeze
      EMPTY = { status: 'empty' }.freeze
      private_constant :EMPTY

      def initialize(request, controller:)
        @request = request
        @controller = controller
      end

      def request_body
        return omitted('non-inertia-request') if WRITE_METHODS.include?(@request.request_method) && !@request.inertia?
        # Rails adds a wrapped copy to JSON params, so use the body as sent.
        return raw_request_body if @request.content_mime_type&.json?

        parameters = @request.request_parameters
        return raw_request_body if parameters.blank?

        present(Redaction.redact_with_log_filters(summarize_uploads(parameters)))
      rescue StandardError
        omitted('unserializable')
      end

      # An Inertia page is stored whole. Other bodies only when they are JSON: secrets can
      # only be hidden there.
      def response_body(status:, content_type:, page:)
        return present(page) if page
        return EMPTY if bodiless?(status)
        return omitted('non-textual') unless TEXTUAL_CONTENT_TYPES.any? { |type| content_type.include?(type) }

        response = controller_response
        return omitted('non-inertia-response') unless content_type.include?('json') && response

        content = buffered_body(response)
        return omitted('streamed') unless content

        json_body(content) { |decoded| Redaction.redact_exact_keys(decoded) }
      end

      private

      def raw_request_body
        json_body(@request.raw_post.to_s) { |decoded| Redaction.redact_with_log_filters(decoded) }
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

      def bodiless?(status)
        (300..399).cover?(status) || Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.key?(status)
      end

      # Middleware has wrapped the Rack body by now, and reading it on Rack 3 closes it.
      def controller_response
        @controller.response if @controller && !@request.env.key?('action_dispatch.exception')
      end

      def buffered_body(response)
        return if @controller.is_a?(ActionController::Live) || response.stream.respond_to?(:to_path)

        body = response.body
        body if body.is_a?(String)
      end

      def json_body(content)
        return EMPTY if content.empty?
        return omitted('too-large') if content.bytesize > RAW_BODY_LIMIT
        return omitted('unserializable') unless content.dup.force_encoding(Encoding::UTF_8).valid_encoding?

        decoded = JSON.parse(content)
        return omitted('unserializable') unless decoded.is_a?(Hash) || decoded.is_a?(Array)

        present(yield(decoded))
      rescue JSON::ParserError
        omitted('unserializable')
      end

      def present(value)
        { status: 'present', value: value }
      end

      def omitted(reason)
        { status: 'omitted', reason: reason }
      end
    end
  end
end
