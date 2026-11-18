# frozen_string_literal: true

module InertiaRails
  # Sends integers beyond JavaScript's safe range as `{ "$bigint": "<digits>" }` markers,
  # which Inertia.js (v3.8+) turns into BigInt values on pages flagged with `preserveBigIntegers`.
  module BigIntegers
    MARKER = '$bigint'
    MAX_SAFE_INTEGER = (2**53) - 1

    class << self
      def encode(value)
        case value
        when Integer then value.abs > MAX_SAFE_INTEGER ? { MARKER => value.to_s } : value
        when String, Symbol, Numeric, true, false, nil then value
        when Hash then value.transform_values { |nested| encode(nested) }
        when Array then value.map { |nested| encode(nested) }
        # Looks inside other objects the way the JSON encoder does, fragments included.
        else encode(defined?(JSON::Fragment) && value.is_a?(JSON::Fragment) ? JSON.parse(value.json) : value.as_json)
        end
      end
    end
  end
end
