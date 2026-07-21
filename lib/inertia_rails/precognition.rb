# frozen_string_literal: true

module InertiaRails
  class PrecognitionResponse < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super('Precognition response')
    end
  end

  module Precognition
    class << self
      # Returns filtered errors hash if precognition request, nil otherwise
      def validate(model_or_errors, &block)
        # Check before the precognitive? guard to catch errors early
        # without waiting for precognition requests.
        ensure_single_precognition_call!
        request = Current.request
        return unless request&.inertia_precognitive?

        errors = normalize_errors(model_or_errors)
        errors = block.call(errors) if block && errors.any?
        errors = flatten_errors(errors)
        filter_errors(errors, request)
      end

      private

      def normalize_errors(errors)
        return errors if errors.is_a?(Hash)

        if errors.respond_to?(:valid?) && errors.respond_to?(:errors)
          errors.valid?
          return errors.errors.to_hash
        end

        return errors.to_hash if errors.respond_to?(:to_hash)
        return errors.to_h if errors.respond_to?(:to_h)

        raise ArgumentError,
              "Expected a Hash or an object responding to :valid? and :errors, :to_hash, or :to_h, got #{errors.class}"
      end

      def flatten_errors(errors, prefix = nil)
        errors.each_with_object({}) do |(key, value), flat|
          full_key = prefix ? "#{prefix}.#{key}" : key.to_s
          if value.is_a?(Hash)
            flat.merge!(flatten_errors(value, full_key))
          else
            flat[full_key] = value
          end
        end
      end

      def filter_errors(errors, request)
        only_keys = request.inertia_precognitive_validate_only
        return errors unless only_keys&.any?

        errors.slice(*only_keys, *only_keys.map(&:to_sym))
      end

      def ensure_single_precognition_call!
        raise DoublePrecognitionError if Current.precognition_called

        Current.precognition_called = true
      end
    end
  end

  def self.precognition!(model_or_errors, &block)
    errors = Precognition.validate(model_or_errors, &block)
    return false if errors.nil?

    raise PrecognitionResponse, errors, []
  end
end
