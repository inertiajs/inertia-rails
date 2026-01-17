# frozen_string_literal: true

require 'inertia_rails/testing'

module InertiaRails
  module Minitest
    module AssertionFactory
      module_function

      def define_partial_assertion(mod, name, field)
        mod.define_method(:"assert_inertia_#{name}") do |expected = nil, message = nil, &block|
          result = if block
                     Testing::Assertions.validate_with_block(inertia, field, &block)
                   else
                     Testing::Assertions.validate_partial_match(inertia, field, expected)
                   end
          assert result[:passed], message || result[:message]
        end

        mod.define_method(:"refute_inertia_#{name}") do |expected = nil, message = nil, &block|
          result = if block
                     Testing::Assertions.validate_with_block(inertia, field, &block)
                   else
                     Testing::Assertions.validate_partial_match(inertia, field, expected)
                   end
          refute result[:passed], message || result[:negated_message]
        end
      end

      def define_exact_assertion(mod, name, field)
        mod.define_method(:"assert_inertia_#{name}_equal") do |expected, message = nil|
          result = Testing::Assertions.validate_exact_match(inertia, field, expected)
          assert result[:passed], message || result[:message]
        end

        mod.define_method(:"refute_inertia_#{name}_equal") do |expected, message = nil|
          result = Testing::Assertions.validate_exact_match(inertia, field, expected)
          refute result[:passed], message || result[:negated_message]
        end
      end

      def define_key_absent_assertion(mod, name, field)
        mod.define_method(:"assert_no_inertia_#{name}") do |key, message = nil|
          result = Testing::Assertions.validate_key_absent(inertia, field, key)
          assert result[:passed], message || result[:message]
        end
      end

      def define_component_assertion(mod)
        mod.define_method(:assert_inertia_component) do |expected, message = nil|
          result = Testing::Assertions.validate_component(inertia, expected)
          assert result[:passed], message || result[:message]
        end

        mod.define_method(:refute_inertia_component) do |expected, message = nil|
          result = Testing::Assertions.validate_component(inertia, expected)
          refute result[:passed], message || result[:negated_message]
        end
      end

      def define_response_assertion(mod)
        mod.define_method(:assert_inertia_response) do |message = nil|
          result = Testing::Assertions.validate_inertia_response(inertia)
          assert result[:passed], message || result[:message]
        end

        mod.define_method(:refute_inertia_response) do |message = nil|
          result = Testing::Assertions.validate_inertia_response(inertia)
          refute result[:passed], message || result[:negated_message]
        end
      end

      def define_deferred_props_assertion(mod)
        mod.define_method(:assert_inertia_deferred_props) do |*keys, group: nil, message: nil|
          result = Testing::Assertions.validate_deferred_props(inertia, *keys, group: group)
          assert result[:passed], message || result[:message]
        end

        mod.define_method(:refute_inertia_deferred_props) do |*keys, group: nil, message: nil|
          result = Testing::Assertions.validate_deferred_props(inertia, *keys, group: group)
          refute result[:passed], message || result[:negated_message]
        end
      end
    end

    module Helpers
      include InertiaRails::Testing::Helpers

      # @deprecated Use {#assert_no_inertia_prop} instead. Will be removed in InertiaRails 4.0.
      def assert_no_inertia_props(key, message = nil)
        InertiaRails.deprecator.warn(
          '`assert_no_inertia_props` is deprecated and will be removed in InertiaRails 4.0, ' \
          'use `assert_no_inertia_prop` (singular) instead.'
        )
        assert_no_inertia_prop(key, message)
      end
    end

    AssertionFactory.define_partial_assertion(Helpers, :props, :props)
    AssertionFactory.define_exact_assertion(Helpers, :props, :props)
    AssertionFactory.define_key_absent_assertion(Helpers, :prop, :props)

    AssertionFactory.define_partial_assertion(Helpers, :view_data, :view_data)
    AssertionFactory.define_exact_assertion(Helpers, :view_data, :view_data)
    AssertionFactory.define_key_absent_assertion(Helpers, :view_data, :view_data)

    AssertionFactory.define_partial_assertion(Helpers, :flash, :flash)
    AssertionFactory.define_exact_assertion(Helpers, :flash, :flash)
    AssertionFactory.define_key_absent_assertion(Helpers, :flash, :flash)

    AssertionFactory.define_component_assertion(Helpers)
    AssertionFactory.define_response_assertion(Helpers)
    AssertionFactory.define_deferred_props_assertion(Helpers)
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include InertiaRails::Minitest::Helpers

  InertiaRails::Testing.install!

  setup do
    InertiaRails::Testing.current_response = nil
  end
end
