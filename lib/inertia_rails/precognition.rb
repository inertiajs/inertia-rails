# frozen_string_literal: true

require_relative 'current'

module InertiaRails
  class PrecognitionResponse < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super('Precognition response')
    end
  end

  module Precognition
    # Returns filtered errors hash if precognition request, nil otherwise
    def self.validate(model_or_errors)
      request = Current.request
      return unless request&.inertia_precognitive?

      errors = normalize_errors(model_or_errors)
      filter_errors(errors, request)
    end

    def self.normalize_errors(errors)
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
    private_class_method :normalize_errors

    def self.filter_errors(errors, request)
      only_keys = request.inertia_precognitive_validate_only
      return errors unless only_keys&.any?

      errors.slice(*only_keys, *only_keys.map(&:to_sym))
    end
    private_class_method :filter_errors
  end

  def self.precognition!(model_or_errors)
    errors = Precognition.validate(model_or_errors)
    return false if errors.nil?

    raise PrecognitionResponse, errors, []
  end
end
