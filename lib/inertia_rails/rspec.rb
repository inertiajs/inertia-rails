# frozen_string_literal: true

require 'rspec/core'
require 'rspec/matchers'
require 'inertia_rails/testing'

module InertiaRails
  module RSpec
    # Backward compatibility alias
    InertiaRenderWrapper = InertiaRails::Testing::TestResponse

    module Helpers
      include InertiaRails::Testing::Helpers

      def inertia
        # First, try thread-local storage (auto-detect mode)
        response = InertiaRails::Testing.current_response

        # Backwards compatibility: check for old instance var if metadata flag used
        if response.nil? && inertia_tests_setup?
          response = @_inertia_render_wrapper
          if response.nil? && !::RSpec.configuration.inertia[:skip_missing_renderer_warnings]
            warn 'WARNING: the test never created an Inertia renderer. ' \
                 "Maybe the code wasn't able to reach a `render inertia:` call? If this was intended, " \
                 "or you don't want to see this message, " \
                 'set ::RSpec.configuration.inertia[:skip_missing_renderer_warnings] = true'
          end
        end

        response
      end

      def expect_inertia
        expect(inertia)
      end

      def inertia_wrap_render(render)
        @_inertia_render_wrapper = InertiaRails::Testing::TestResponse.new.wrap_render(render)
      end

      protected

      def inertia_tests_setup?
        ::RSpec.current_example.metadata.fetch(:inertia, false)
      end
    end
  end
end

RSpec.configure do |config|
  config.include InertiaRails::RSpec::Helpers
  config.add_setting :inertia, default: {
    skip_missing_renderer_warnings: false,
  }

  # Auto-install on suite start
  config.before(:suite) do
    InertiaRails::Testing.install!
  end

  # Reset current_response before each test
  config.before(:each) do
    InertiaRails::Testing.current_response = nil
  end

  # Deprecated: inertia: true flag (kept for backwards compatibility)
  config.before(:each, inertia: true) do
    InertiaRails.deprecator.warn(
      'The `inertia: true` metadata flag is deprecated and will be removed in InertiaRails 4.0. ' \
      'Inertia test helpers are now auto-enabled. Simply remove the flag.'
    )
    # Keep existing behavior for backwards compatibility
    new_renderer = InertiaRails::Renderer.method(:new)
    allow(InertiaRails::Renderer).to receive(:new) do |component, controller, request, response, render, named_args|
      new_renderer.call(component, controller, request, response, inertia_wrap_render(render), **(named_args || {}))
    end
  end
end

# Props matchers
RSpec::Matchers.define :have_exact_props do |expected_props|
  match do |inertia|
    @result = InertiaRails::Testing::Assertions.validate_exact_match(inertia&.props, expected_props, 'props')
    @result[:passed]
  end

  failure_message { @result[:message] }
end

RSpec::Matchers.define :have_props do |expected_props|
  match do |inertia|
    @result = InertiaRails::Testing::Assertions.validate_partial_match(inertia&.props, expected_props, 'props')
    @result[:passed]
  end

  failure_message { @result[:message] }
end

# Deprecated: use have_props instead
RSpec::Matchers.define :include_props do |expected_props|
  match do |inertia|
    InertiaRails.deprecator.warn(
      '`include_props` is deprecated and will be removed in InertiaRails 4.0, use `have_props` instead.'
    )
    @result = InertiaRails::Testing::Assertions.validate_partial_match(inertia&.props, expected_props, 'props')
    @result[:passed]
  end

  failure_message { @result[:message] }
end

# View data matchers
RSpec::Matchers.define :have_exact_view_data do |expected_view_data|
  match do |inertia|
    assertions = InertiaRails::Testing::Assertions
    @result = assertions.validate_exact_match(inertia&.view_data, expected_view_data, 'view data')
    @result[:passed]
  end

  failure_message { @result[:message] }
end

RSpec::Matchers.define :have_view_data do |expected_view_data|
  match do |inertia|
    assertions = InertiaRails::Testing::Assertions
    @result = assertions.validate_partial_match(inertia&.view_data, expected_view_data, 'view_data')
    @result[:passed]
  end

  failure_message { @result[:message] }
end

# Deprecated: use have_view_data instead
RSpec::Matchers.define :include_view_data do |expected_view_data|
  match do |inertia|
    InertiaRails.deprecator.warn(
      '`include_view_data` is deprecated and will be removed in InertiaRails 4.0, use `have_view_data` instead.'
    )
    assertions = InertiaRails::Testing::Assertions
    @result = assertions.validate_partial_match(inertia&.view_data, expected_view_data, 'view_data')
    @result[:passed]
  end

  failure_message { @result[:message] }
end

# Flash matchers
RSpec::Matchers.define :have_flash do |expected_flash|
  match do |inertia|
    @result = InertiaRails::Testing::Assertions.validate_partial_match(inertia&.flash, expected_flash, 'flash')
    @result[:passed]
  end

  failure_message { @result[:message] }
end

RSpec::Matchers.define :have_exact_flash do |expected_flash|
  match do |inertia|
    @result = InertiaRails::Testing::Assertions.validate_exact_match(inertia&.flash, expected_flash, 'flash')
    @result[:passed]
  end

  failure_message { @result[:message] }
end

# Component matcher
RSpec::Matchers.define :render_component do |expected_component|
  match do |inertia|
    @actual = inertia&.component
    @actual == expected_component
  end

  failure_message do
    actual_display = @actual.nil? ? 'nothing' : @actual.inspect
    "expected rendered inertia component to be #{expected_component.inspect}, " \
      "instead received #{actual_display}"
  end
end

# Deferred props matcher
RSpec::Matchers.define :have_deferred_props do |expected = nil|
  match do |inertia|
    @result = InertiaRails::Testing::Assertions.validate_deferred_props(inertia&.deferred_props, expected)
    @result[:passed]
  end

  failure_message { @result[:message] }
end

# Response type matcher
RSpec::Matchers.define :be_inertia_response do
  match do |_actual|
    InertiaRails::Testing.current_response&.component.present?
  end

  failure_message do
    'expected response to be an Inertia response, but no Inertia component was rendered'
  end

  failure_message_when_negated do
    'expected response not to be an Inertia response, but an Inertia component was rendered'
  end
end
