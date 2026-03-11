# frozen_string_literal: true

module InertiaRails
  module InertiaRequest
    def inertia?
      key? 'HTTP_X_INERTIA'
    end

    def inertia_partial?
      key?('HTTP_X_INERTIA_PARTIAL_COMPONENT')
    end

    def inertia_precognitive?
      headers['Precognition'] == 'true'
    end

    def inertia_precognitive_validate_only
      headers['Precognition-Validate-Only']&.split(',')&.map(&:strip)
    end
  end
end

ActionDispatch::Request.include InertiaRails::InertiaRequest
