# frozen_string_literal: true

require 'uri'
require 'active_support/parameter_filter'

module InertiaRails
  module Devtools
    module Redaction
      REDACTED = '[REDACTED]'
      UNSERIALIZABLE = '[UNSERIALIZABLE]'
      URL_KEYS = %w[url redirectlocation].freeze
      URL_HEADERS = %w[location content-location referer refresh].freeze
      SENSITIVE_PROBE = 'inertia-devtools-probe'

      module_function

      def redact_headers_keys
        normalize(InertiaRails.configuration.devtools_redact_headers)
      end

      def redact(value, filter = parameter_filter)
        case value
        when Hash
          filter.filter(value)
        when Array
          value.map { |item| redact(item, filter) }
        else
          value
        end
      end

      def redact_headers(headers)
        keys = redact_headers_keys

        headers.each_with_object({}) do |(name, value), result|
          result[name] = if sensitive_header?(name, keys)
                           REDACTED
                         else
                           value = value.is_a?(Array) ? value.join(', ') : value.to_s
                           url_header?(name) ? redact_url(value) : value
                         end
        end
      end

      def url_header?(name)
        (name.is_a?(String) || name.is_a?(Symbol)) && URL_HEADERS.include?(name.to_s.downcase)
      end

      def redact_payload(payload)
        sanitize(redact_urls(payload))
      end

      def redact_urls(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), result|
            result[key] = if nested.is_a?(String) && URL_KEYS.include?(key.to_s.downcase)
                            redact_url(nested)
                          else
                            redact_urls(nested)
                          end
          end
        when Array
          value.map { |item| redact_urls(item) }
        else
          value
        end
      end

      def redact_url(url)
        return url unless url.include?('?')

        filter = parameter_filter
        uri = URI.parse(url)
        return url if uri.query.nil? || uri.query.empty?

        uri.query = URI.encode_www_form(
          URI.decode_www_form(uri.query).map do |key, value|
            [key, sensitive_query_key?(key, filter) ? REDACTED : value]
          end
        )

        uri.to_s
      rescue StandardError
        # Fail closed when a query cannot be parsed.
        "#{url.split('?').first}?#{REDACTED}"
      end

      def sanitize(value)
        case value
        when Hash
          value.transform_values { |nested| sanitize(nested) }
        when Array
          value.map { |item| sanitize(item) }
        when String
          utf8?(value) || encodable?(value) ? value : UNSERIALIZABLE
        when Numeric
          value.respond_to?(:finite?) && !value.finite? ? UNSERIALIZABLE : value
        when TrueClass, FalseClass, NilClass
          value
        else
          encodable?(value) ? value : UNSERIALIZABLE
        end
      end

      def utf8?(value)
        value.encoding == Encoding::UTF_8 && value.valid_encoding?
      end

      def encodable?(value)
        JSON.generate([value])
        true
      rescue StandardError
        false
      end

      def sensitive_param?(key, filter = parameter_filter)
        return false unless key.is_a?(String) || key.is_a?(Symbol)

        filter.filter_param(key.to_s, SENSITIVE_PROBE) != SENSITIVE_PROBE
      end

      def sensitive_query_key?(key, filter)
        key.scan(/[^\[\]]+/).any? { |segment| sensitive_param?(segment, filter) }
      end

      def sensitive_header?(name, keys)
        name.is_a?(String) || name.is_a?(Symbol) ? keys.include?(name.to_s.downcase) : false
      end

      def parameter_filter
        app_filters = application_filter_parameters
        keys = Array(InertiaRails.configuration.devtools_redact_keys)

        cached = @parameter_filter
        return cached[2] if cached && cached[0] == app_filters && cached[1] == keys

        filter = ActiveSupport::ParameterFilter.new(app_filters + exact_matchers(keys), mask: REDACTED)
        @parameter_filter = [app_filters, keys, filter]
        filter
      end

      def application_filter_parameters
        Rails.application&.config&.filter_parameters || []
      rescue StandardError
        []
      end

      def exact_matchers(keys)
        normalize(keys).map { |key| /\A#{Regexp.escape(key)}\z/i }
      end

      def normalize(keys)
        Array(keys).filter_map { |key| key.to_s.downcase.presence }.uniq
      end
    end
  end
end
