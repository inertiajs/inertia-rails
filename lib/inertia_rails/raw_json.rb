# frozen_string_literal: true

module InertiaRails
  # Wraps a pre-serialized JSON string so it embeds directly
  # into a larger JSON structure without re-serialization.
  class RawJson
    def initialize(json_string)
      @json_string = json_string
    end

    def to_json(*)
      @json_string
    end

    def as_json(*)
      self
    end
  end
end
