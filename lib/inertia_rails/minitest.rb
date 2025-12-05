# frozen_string_literal: true

require 'minitest'

module InertiaRails
  module Minitest
    class InertiaRenderWrapper
      attr_reader :view_data, :props, :component

      def initialize
        @view_data = nil
        @props = nil
        @component = nil
      end

      def call(params)
        assign_locals(params)
        @render_method&.call(params)
      end

      def wrap_render(render_method)
        @render_method = render_method
        self
      end

      protected

      def assign_locals(params)
        if params[:locals].present?
          @view_data = params[:locals].except(:page)
          @props = params[:locals][:page][:props]
          @component = params[:locals][:page][:component]
        else
          # Sequential Inertia request
          @view_data = {}
          json = JSON.parse(params[:json])
          @props = json['props']
          @component = json['component']
        end
      end
    end

    class Configuration
      attr_accessor :skip_missing_renderer_warnings

      def initialize
        @skip_missing_renderer_warnings = false
      end
    end

    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield(config) if block_given?
      end
    end

    module Helpers
      def inertia
        if @_inertia_render_wrapper.nil? && !InertiaRails::Minitest.config.skip_missing_renderer_warnings
          warn 'WARNING: the test never created an Inertia renderer. ' \
               "Maybe the code wasn't able to reach a `render inertia:` call? If this was intended, " \
               "or you don't want to see this message, " \
               'set InertiaRails::Minitest.config.skip_missing_renderer_warnings = true'
        end
        @_inertia_render_wrapper
      end

      def inertia_wrap_render(render)
        @_inertia_render_wrapper = InertiaRenderWrapper.new.wrap_render(render)
      end

      # Assertion: Asserts that the rendered component matches the expected component name
      def assert_inertia_component(expected_component, message = nil)
        message ||= "Expected rendered inertia component to be #{expected_component.inspect}, " \
                    "instead received #{inertia&.component.inspect || 'nothing'}"
        assert_equal expected_component, inertia&.component, message
      end

      # Assertion: Asserts that props match exactly (no extra or missing keys)
      def assert_inertia_exact_props(expected_props, message = nil)
        message ||= "Expected inertia props to receive #{expected_props.inspect}, " \
                    "instead received #{inertia&.props.inspect || 'nothing'}"
        assert_equal expected_props, inertia&.props, message
      end

      # Assertion: Asserts that props include the specified keys/values (allows extra keys)
      def assert_inertia_includes_props(expected_props, message = nil)
        actual_props = inertia&.props || {}
        message ||= "Expected inertia props to include #{expected_props.inspect}, " \
                    "instead received #{actual_props.inspect}"

        expected_props.each do |key, value|
          assert_includes actual_props.keys, key,
                         "Expected props to include key #{key.inspect}, but it was not present. " \
                         "Available keys: #{actual_props.keys.inspect}"
          assert_equal value, actual_props[key],
                      "Expected props[#{key.inspect}] to be #{value.inspect}, " \
                      "but got #{actual_props[key].inspect}"
        end
      end

      # Assertion: Asserts that view data matches exactly
      def assert_inertia_exact_view_data(expected_view_data, message = nil)
        message ||= "Expected inertia view data to receive #{expected_view_data.inspect}, " \
                    "instead received #{inertia&.view_data.inspect || 'nothing'}"
        assert_equal expected_view_data, inertia&.view_data, message
      end

      # Assertion: Asserts that view data includes the specified keys/values
      def assert_inertia_includes_view_data(expected_view_data, message = nil)
        actual_view_data = inertia&.view_data || {}
        message ||= "Expected inertia view data to include #{expected_view_data.inspect}, " \
                    "instead received #{actual_view_data.inspect}"

        expected_view_data.each do |key, value|
          assert_includes actual_view_data.keys, key,
                         "Expected view data to include key #{key.inspect}, but it was not present. " \
                         "Available keys: #{actual_view_data.keys.inspect}"
          assert_equal value, actual_view_data[key],
                      "Expected view_data[#{key.inspect}] to be #{value.inspect}, " \
                      "but got #{actual_view_data[key].inspect}"
        end
      end

      def self.included(base)
        # Only set up hooks if the base class supports them (Minitest::Test subclasses)
        if base.respond_to?(:setup) && base.respond_to?(:teardown)
          base.class_eval do
            setup do
              # Intercept InertiaRails::Renderer.new to wrap the render method
              @_original_renderer_new = InertiaRails::Renderer.method(:new)

              InertiaRails::Renderer.define_singleton_method(:new) do |component, controller, request, response, render, named_args|
                @_original_renderer_new.call(
                  component,
                  controller,
                  request,
                  response,
                  controller.inertia_wrap_render(render),
                  **(named_args || {})
                )
              end
            end

            teardown do
              # Restore the original Renderer.new method
              if @_original_renderer_new
                InertiaRails::Renderer.define_singleton_method(:new, @_original_renderer_new)
              end
            end
          end
        end
      end
    end
  end
end
