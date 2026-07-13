# frozen_string_literal: true

require 'rspec/core'
require 'rspec/matchers'
require 'inertia_rails/testing'
require 'inertia_rails/rspec/deprecated'

module InertiaRails
  module RSpec
    # @deprecated Will be removed in InertiaRails 4.0
    InertiaRenderWrapper = InertiaRails::Testing::TestResponse

    module MatcherFactory
      class << self
        def define_inertia_matcher(name, &validation_block)
          ::RSpec::Matchers.define(name) do |*matcher_args|
            match do |actual|
              @result = instance_exec(actual, *matcher_args, &validation_block)
              @result[:passed]
            end

            failure_message { @result[:message] }
            failure_message_when_negated { @result[:negated_message] }
          end
        end

        def define_partial_matcher(name, field)
          ::RSpec::Matchers.define(name) do |expected = nil|
            match do |inertia|
              @result = if block_arg
                          Testing::Assertions.validate_with_block(inertia, field, &block_arg)
                        else
                          Testing::Assertions.validate_partial_match(inertia, field, expected)
                        end
              @result[:passed]
            end

            failure_message { @result[:message] }
            failure_message_when_negated { @result[:negated_message] }
          end
        end

        def define_exact_matcher(name, field)
          define_inertia_matcher(name) do |inertia, expected|
            Testing::Assertions.validate_exact_match(inertia, field, expected)
          end
        end

        def define_key_absent_matcher(name, field)
          define_inertia_matcher(name) do |inertia, key|
            Testing::Assertions.validate_key_absent(inertia, field, key)
          end
        end
      end
    end

    module Helpers
      include Testing::Helpers
      include RSpec::DeprecatedHelpers

      def inertia
        super || inertia_from_deprecated_flag
      end

      def expect_inertia
        expect(inertia)
      end
    end
  end
end

RSpec.configure do |config|
  config.include InertiaRails::RSpec::Helpers
  config.add_setting :inertia, default: {
    skip_missing_renderer_warnings: false,
  }

  config.before(:suite) do
    InertiaRails::Testing.install!
  end

  config.before(:each) do
    InertiaRails::Testing.current_response = nil
  end

  InertiaRails::RSpec::DeprecatedConfiguration.install!(config)
end

InertiaRails::RSpec::MatcherFactory.define_partial_matcher(:have_props, :props)
InertiaRails::RSpec::MatcherFactory.define_exact_matcher(:have_exact_props, :props)
InertiaRails::RSpec::MatcherFactory.define_key_absent_matcher(:have_no_prop, :props)

InertiaRails::RSpec::MatcherFactory.define_partial_matcher(:have_view_data, :view_data)
InertiaRails::RSpec::MatcherFactory.define_exact_matcher(:have_exact_view_data, :view_data)
InertiaRails::RSpec::MatcherFactory.define_key_absent_matcher(:have_no_view_data, :view_data)

InertiaRails::RSpec::MatcherFactory.define_partial_matcher(:have_flash, :flash)
InertiaRails::RSpec::MatcherFactory.define_exact_matcher(:have_exact_flash, :flash)
InertiaRails::RSpec::MatcherFactory.define_key_absent_matcher(:have_no_flash, :flash)

RSpec::Matchers.define(:have_deferred_props) do |*expected_keys, **options|
  match do |inertia|
    @result = InertiaRails::Testing::Assertions.validate_deferred_props(inertia, *expected_keys, **options)
    @result[:passed]
  end

  failure_message { @result[:message] }
  failure_message_when_negated { @result[:negated_message] }
end

InertiaRails::RSpec::MatcherFactory.define_inertia_matcher(:be_inertia_response) do |inertia|
  InertiaRails::Testing::Assertions.validate_inertia_response(inertia)
end

InertiaRails::RSpec::MatcherFactory.define_inertia_matcher(:render_component) do |inertia, expected|
  InertiaRails::Testing::Assertions.validate_component(inertia, expected)
end

InertiaRails::RSpec::DeprecatedMatchers.install!
