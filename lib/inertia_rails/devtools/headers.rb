# frozen_string_literal: true

module InertiaRails
  module Devtools
    module Headers
      # Response
      ID = 'X-Inertia-Devtools-Id'
      PARENT_OUT = 'X-Inertia-Devtools-Parent-Out'

      # Request (Rack env keys)
      PARENT = 'HTTP_X_INERTIA_DEVTOOLS_PARENT'
      TAB = 'HTTP_X_INERTIA_DEVTOOLS_TAB'
      VISIT = 'HTTP_X_INERTIA_DEVTOOLS_VISIT'
      DEFERRED = 'HTTP_X_INERTIA_DEVTOOLS_DEFERRED'
      POLL = 'HTTP_X_INERTIA_DEVTOOLS_POLL'

      def self.read(env, key)
        value = env[key]
        value if value.is_a?(String) && !value.empty?
      end
    end
  end
end
