# frozen_string_literal: true

require 'inertia_rails/testing'

module InertiaRails
  module Minitest
    module Helpers
      include InertiaRails::Testing::Helpers

      # Rails-like assertions

      # Assert this is an Inertia response
      def assert_inertia_response(message = nil)
        assert inertia&.component.present?,
               message || 'Expected response to be an Inertia response'
      end

      # Assert this is not an Inertia response
      def refute_inertia_response(message = nil)
        refute inertia&.component.present?,
               message || 'Expected response not to be an Inertia response'
      end

      # Assert the rendered Inertia component name
      def assert_inertia_component(expected, message = nil)
        assert_equal expected, inertia&.component,
                     message || "Expected Inertia component to be #{expected.inspect}"
      end

      # Assert props contain expected key/value pairs (partial match)
      def assert_inertia_props(expected, message = nil)
        result = Testing::Assertions.validate_partial_match(inertia&.props, expected, 'props')
        assert result[:passed], message || result[:message]
      end

      # Assert props match exactly
      def assert_inertia_props_equal(expected, message = nil)
        result = Testing::Assertions.validate_exact_match(inertia&.props, expected, 'props')
        assert result[:passed], message || result[:message]
      end

      # Assert view_data contains expected key/value pairs (partial match)
      def assert_inertia_view_data(expected, message = nil)
        result = Testing::Assertions.validate_partial_match(inertia&.view_data, expected, 'view_data')
        assert result[:passed], message || result[:message]
      end

      # Assert view_data matches exactly
      def assert_inertia_view_data_equal(expected, message = nil)
        result = Testing::Assertions.validate_exact_match(inertia&.view_data, expected, 'view_data')
        assert result[:passed], message || result[:message]
      end

      # Assert prop key doesn't exist
      def assert_no_inertia_prop(key, message = nil)
        result = Testing::Assertions.validate_key_absent(inertia&.props, key, 'prop')
        assert result[:passed], message || result[:message]
      end

      # Flash assertions

      # Assert flash contains expected key/value pairs (partial match)
      def assert_inertia_flash(expected, message = nil)
        result = Testing::Assertions.validate_partial_match(inertia&.flash, expected, 'flash')
        assert result[:passed], message || result[:message]
      end

      # Assert flash matches exactly
      def assert_inertia_flash_equal(expected, message = nil)
        result = Testing::Assertions.validate_exact_match(inertia&.flash, expected, 'flash')
        assert result[:passed], message || result[:message]
      end

      # Assert flash key doesn't exist
      def assert_no_inertia_flash(key, message = nil)
        result = Testing::Assertions.validate_key_absent(inertia&.flash, key, 'flash')
        assert result[:passed], message || result[:message]
      end

      # Deferred props assertions

      # Assert deferred props exist or match expected structure
      def assert_inertia_deferred_props(expected = nil, message = nil)
        result = Testing::Assertions.validate_deferred_props(inertia&.deferred_props, expected)
        assert result[:passed], message || result[:message]
      end
    end
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include InertiaRails::Minitest::Helpers

  InertiaRails::Testing.install!

  # Reset current_response before each test
  setup do
    InertiaRails::Testing.current_response = nil
  end
end
