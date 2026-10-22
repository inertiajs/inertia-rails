# frozen_string_literal: true

module InertiaRails
  # Wraps a pre-serialized JSON string so it embeds directly
  # into a larger JSON structure without re-serialization.
  #
  # - JSON.generate calls #to_json, embedding the raw string.
  # - ActiveSupport::JSON.encode calls #as_json first, which
  #   returns parsed Ruby data that the encoder re-serializes.
  class RawJson
    class << self
      # Returns a JSON::Fragment when the app's JSON encoder embeds fragments
      # as they are (Active Support 8.1+), so the string is never parsed again.
      # Otherwise returns a RawJson.
      def wrap(json_string)
        fragment_embeddable? ? ::JSON::Fragment.new(json_string) : new(json_string)
      end

      # Checked once by encoding a fragment, since older encoders and
      # replacements such as Oj serialize it as a plain struct instead.
      def fragment_embeddable?
        return @fragment_embeddable if defined?(@fragment_embeddable)

        @fragment_embeddable = defined?(::JSON::Fragment) &&
                               ActiveSupport::JSON.encode([::JSON::Fragment.new('1')]) == '[1]'
      end
    end

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
