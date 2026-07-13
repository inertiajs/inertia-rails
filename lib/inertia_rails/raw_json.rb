# frozen_string_literal: true

module InertiaRails
  # Wraps a pre-serialized JSON string so it embeds directly
  # into a larger JSON structure without re-serialization.
  #
  # - JSON.generate calls #to_json, embedding the raw string.
  # - ActiveSupport::JSON.encode calls #as_json first, which
  #   returns parsed Ruby data that the encoder re-serializes.
  class RawJson
    def initialize(json_string)
      @json_string = json_string
    end

    def to_json(*)
      @json_string
    end

    def as_json(*)
      JSON.parse(@json_string)
    end
  end
end
