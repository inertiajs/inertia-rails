# frozen_string_literal: true

require 'uri'

module InertiaRails
  module Devtools
    # Exact, case-insensitive key matching — `api_key` is redacted, `stripe_api_key`
    # is not. A matched key redacts its whole subtree.
    module Redaction
      REDACTED = '[REDACTED]'
      UNSERIALIZABLE = '[UNSERIALIZABLE]'
      URL_KEYS = %w[url redirectlocation].freeze
      HEADER_BAG_KEYS = %w[requestheaders responseheaders].freeze

      module_function

      def redact_keys
        normalize(InertiaRails.configuration.devtools_redact_keys)
      end

      def redact_headers_keys
        normalize(InertiaRails.configuration.devtools_redact_headers)
      end

      def redact(value, keys = redact_keys)
        return value if keys.empty?

        case value
        when Hash
          value.each_with_object({}) do |(key, nested), result|
            result[key] = sensitive?(key, keys) ? REDACTED : redact(nested, keys)
          end
        when Array
          value.map { |item| redact(item, keys) }
        else
          value
        end
      end

      def redact_headers(headers)
        keys = redact_headers_keys

        headers.each_with_object({}) do |(name, value), result|
          result[name] = if sensitive?(name, keys)
                           REDACTED
                         else
                           value.is_a?(Array) ? value.join(', ') : value.to_s
                         end
        end
      end

      # Applied to the whole envelope on the way to disk, on top of the per-surface
      # redaction the builder already did.
      def redact_payload(payload)
        keys = redact_keys
        payload = redact(payload, keys)
        payload = redact_urls(payload, keys)
        payload = redact_header_bags(payload)
        sanitize(payload)
      end

      def redact_urls(value, keys)
        return value if keys.empty?

        case value
        when Hash
          value.each_with_object({}) do |(key, nested), result|
            result[key] = if nested.is_a?(String) && URL_KEYS.include?(key.to_s.downcase)
                            redact_url(nested, keys)
                          else
                            redact_urls(nested, keys)
                          end
          end
        when Array
          value.map { |item| redact_urls(item, keys) }
        else
          value
        end
      end

      def redact_url(url, keys)
        return url unless url.include?('?')

        uri = URI.parse(url)
        return url if uri.query.nil? || uri.query.empty?

        uri.query = URI.encode_www_form(
          URI.decode_www_form(uri.query).map { |key, value| [key, sensitive?(key, keys) ? REDACTED : value] }
        )
        uri.to_s
      rescue StandardError
        # Redaction must never break the recorder.
        url
      end

      def redact_header_bags(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), result|
            result[key] = if nested.is_a?(Hash) && HEADER_BAG_KEYS.include?(key.to_s.downcase)
                            redact_headers(nested)
                          else
                            redact_header_bags(nested)
                          end
          end
        when Array
          value.map { |item| redact_header_bags(item) }
        else
          value
        end
      end

      # Replaces individual leaves that cannot be JSON encoded, keeping the
      # surrounding structure intact.
      def sanitize(value)
        case value
        when Hash
          value.transform_values { |nested| sanitize(nested) }
        when Array
          value.map { |item| sanitize(item) }
        when String, Numeric, TrueClass, FalseClass, NilClass
          value
        else
          encodable?(value) ? value : UNSERIALIZABLE
        end
      end

      def encodable?(value)
        JSON.generate([value])
        true
      rescue StandardError
        false
      end

      def sensitive?(key, keys)
        key.is_a?(String) || key.is_a?(Symbol) ? keys.include?(key.to_s.downcase) : false
      end

      def normalize(keys)
        Array(keys).filter_map { |key| key.to_s.downcase.presence }.uniq
      end
    end
  end
end
