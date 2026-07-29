# frozen_string_literal: true

module InertiaRails
  module Devtools
    module Headers
      ID = 'X-Inertia-Devtools-Id'
      PARENT_OUT = 'X-Inertia-Devtools-Parent-Out'
      PARENT = 'HTTP_X_INERTIA_DEVTOOLS_PARENT'
      TAB = 'HTTP_X_INERTIA_DEVTOOLS_TAB'
      VISIT = 'HTTP_X_INERTIA_DEVTOOLS_VISIT'
      DEFERRED = 'HTTP_X_INERTIA_DEVTOOLS_DEFERRED'
      POLL = 'HTTP_X_INERTIA_DEVTOOLS_POLL'

      def self.read(env, key)
        value = env[key]
        value if value.is_a?(String) && !value.empty?
      end

      # Rack 3 requires lowercase response header names.
      def self.response_keys
        defined?(Rack::Headers) ? [ID.downcase, PARENT_OUT.downcase] : [ID, PARENT_OUT]
      end
    end
  end
end
