# frozen_string_literal: true

require 'uri'
require 'active_support/parameter_filter'

module InertiaRails
  module Devtools
    module Redaction
      REDACTED = '[REDACTED]'
      ENCODED_REDACTED = URI.encode_www_form_component(REDACTED)
      URL_HEADERS = %w[location content-location referer refresh x-inertia-location].freeze
      SENSITIVE_PROBE = 'inertia-devtools-probe'

      class << self
        # Request params and bodies: the app's log filters plus redact_keys.
        def redact_with_log_filters(value)
          redact(value, log_filter)
        end

        # Props and response bodies: redact_keys only, matched exactly. Log filters also match
        # parts of names, like `email` or `cache_key`, which would hide props you want to see.
        def redact_exact_keys(value)
          redact(value, ActiveSupport::ParameterFilter.new(exact_matchers, mask: REDACTED))
        end

        def redact_headers(headers)
          keys = normalize(Devtools.config.redact_headers)

          headers.to_h do |name, value|
            next [name, REDACTED] if keys.include?(name)

            value = Array(value).map { |part| utf8(part) }.join(', ')
            [name, URL_HEADERS.include?(name) ? redact_url(value) : value]
          end
        end

        # A URL without secrets stays exactly as it was: the extension matches prefetches by URL.
        def redact_url(url)
          base, fragment = url.split('#', 2)
          path, query = base.split('?', 2)
          return url if query.nil? || query.empty?

          filter = log_filter
          query = query.gsub(/[^&;]+/) do |pair|
            key, value = pair.split('=', 2)
            sensitive = value && sensitive_query_key?(URI.decode_www_form_component(key), filter)
            sensitive ? "#{key}=#{ENCODED_REDACTED}" : pair
          end

          fragment ? "#{path}?#{query}##{fragment}" : "#{path}?#{query}"
        rescue StandardError
          # If the query can't be read, hide all of it.
          "#{url.split('?').first}?#{REDACTED}"
        end

        private

        def redact(value, filter)
          case value
          when Hash then filter.filter(value)
          when Array then value.map { |item| redact(item, filter) }
          else value
          end
        end

        def sensitive_query_key?(key, filter)
          key.scan(/[^\[\]]+/).any? { |segment| filter.filter_param(segment, SENSITIVE_PROBE) != SENSITIVE_PROBE }
        end

        def log_filter
          filters = Rails.application.config.filter_parameters + exact_matchers
          ActiveSupport::ParameterFilter.new(filters, mask: REDACTED)
        end

        # One regexp for all plain keys is faster, but Rails' filter reads a dot as a nested key,
        # so keys with dots get their own.
        def exact_matchers
          dotted, plain = normalize(Devtools.config.redact_keys).partition { |key| key.include?('.') }
          [/\A(?:#{Regexp.union(plain).source})\z/i, *dotted.map { |key| /\A#{Regexp.escape(key)}\z/i }]
        end

        # Header bytes arrive raw; invalid ones become U+FFFD so the entry can still be written.
        def utf8(value)
          value.to_s.dup.force_encoding(Encoding::UTF_8).scrub
        end

        def normalize(keys)
          Array(keys).filter_map { |key| key.to_s.downcase.presence }.uniq
        end
      end
    end
  end
end
