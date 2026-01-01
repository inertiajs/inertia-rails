# frozen_string_literal: true

module InertiaRails
  module RSpec
    # @deprecated Will be removed in InertiaRails 4.0
    module DeprecatedHelpers
      # @deprecated Will be removed in InertiaRails 4.0
      def inertia_wrap_render(render)
        @_inertia_render_wrapper = InertiaRails::Testing::TestResponse.new.wrap_render(render)
      end

      private

      def inertia_from_deprecated_flag
        return unless inertia_tests_setup?

        response = @_inertia_render_wrapper
        warn_missing_renderer if response.nil?
        response
      end

      def inertia_tests_setup?
        ::RSpec.current_example.metadata.fetch(:inertia, false)
      end

      def warn_missing_renderer
        return if ::RSpec.configuration.inertia[:skip_missing_renderer_warnings]

        warn 'WARNING: the test never created an Inertia renderer. ' \
             "Maybe the code wasn't able to reach a `render inertia:` call? If this was intended, " \
             "or you don't want to see this message, " \
             'set ::RSpec.configuration.inertia[:skip_missing_renderer_warnings] = true'
      end
    end

    # @deprecated Will be removed in InertiaRails 4.0
    module DeprecatedMatchers
      def self.install!
        ::RSpec::Matchers.define :include_props do |expected|
          match do |inertia|
            InertiaRails.deprecator.warn(
              '`include_props` is deprecated and will be removed in InertiaRails 4.0, use `have_props` instead.'
            )
            @result = InertiaRails::Testing::Assertions.validate_partial_match(inertia, :props, expected)
            @result[:passed]
          end

          failure_message { @result[:message] }
          failure_message_when_negated { @result[:negated_message] }
        end

        ::RSpec::Matchers.define :include_view_data do |expected|
          match do |inertia|
            InertiaRails.deprecator.warn(
              '`include_view_data` is deprecated and will be removed in InertiaRails 4.0, use `have_view_data` instead.'
            )
            @result = InertiaRails::Testing::Assertions.validate_partial_match(inertia, :view_data, expected)
            @result[:passed]
          end

          failure_message { @result[:message] }
          failure_message_when_negated { @result[:negated_message] }
        end
      end
    end

    # @deprecated Will be removed in InertiaRails 4.0
    module DeprecatedConfiguration
      def self.install!(config)
        config.before(:each, inertia: true) do
          InertiaRails.deprecator.warn(
            'The `inertia: true` metadata flag is deprecated and will be removed in InertiaRails 4.0. ' \
            'Inertia test helpers are now auto-enabled. Simply remove the flag.'
          )
          new_renderer = InertiaRails::Renderer.method(:new)
          # rubocop:disable Layout/LineLength
          allow(InertiaRails::Renderer).to receive(:new) do |component, controller, request, response, render, named_args|
            # rubocop:enable Layout/LineLength
            new_renderer.call(
              component, controller, request, response, inertia_wrap_render(render), **(named_args || {})
            )
          end
        end
      end
    end
  end
end
