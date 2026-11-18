# frozen_string_literal: true

module InertiaRails
  # Wraps a pre-serialized JSON string so it embeds directly
  # into a larger JSON structure without re-serialization.
  #
  # - JSON.generate calls #to_json, embedding the raw string.
  # - ActiveSupport::JSON.encode calls #as_json first. It gets a JSON::Fragment
  #   where the encoder writes one as it is, and parsed Ruby data to
  #   re-serialize everywhere else.
  class RawJson
    # Ask the encoder itself. Active Support 8.1 writes a fragment as it is;
    # older versions and replacements such as Oj turn it into {"json": "..."}.
    def self.encoder_embeds_fragments?
      return @encoder_embeds_fragments if defined?(@encoder_embeds_fragments)

      @encoder_embeds_fragments = defined?(::JSON::Fragment) &&
                                  ActiveSupport::JSON.encode(::JSON::Fragment.new('"raw"')) == '"raw"'
    end

    def initialize(json_string)
      @json_string = json_string
    end

    def to_json(*)
      @json_string
    end

    def as_json(*)
      self.class.encoder_embeds_fragments? ? ::JSON::Fragment.new(@json_string) : JSON.parse(@json_string)
    end
  end
end
