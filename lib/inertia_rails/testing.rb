# frozen_string_literal: true

module InertiaRails
  module Testing
    # Thread-local storage for test response
    thread_mattr_accessor :current_response

    # Patch Renderer.new to capture test responses
    def self.install!
      return if @installed

      original_new = InertiaRails::Renderer.method(:new)
      InertiaRails::Renderer.define_singleton_method(:new) do |comp, ctrl, req, res, render, **opts|
        wrapped = TestResponse.new.wrap_render(render)
        InertiaRails::Testing.current_response = wrapped
        original_new.call(comp, ctrl, req, res, wrapped, **opts)
      end
      @installed = true
    end

    # Captures Inertia render data for test assertions
    class TestResponse
      attr_reader :view_data, :props, :component, :flash, :deferred_props

      def initialize
        @view_data = nil
        @props = nil
        @component = nil
        @flash = nil
        @deferred_props = nil
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
          @view_data = params[:locals].except(:page).with_indifferent_access
          page = params[:locals][:page]
          @props = (page[:props] || {}).with_indifferent_access
          @component = page[:component]
          @flash = (page[:flash] || {}).with_indifferent_access
          @deferred_props = (page[:deferredProps] || {}).with_indifferent_access
        else
          # Sequential Inertia request
          @view_data = {}.with_indifferent_access
          json = JSON.parse(params[:json])
          @props = (json['props'] || {}).with_indifferent_access
          @component = json['component']
          @flash = (json['flash'] || {}).with_indifferent_access
          @deferred_props = (json['deferredProps'] || {}).with_indifferent_access
        end
      end
    end

    # Shared assertion validators - return { passed:, actual:, message: }
    # Used by both RSpec matchers and Minitest assertions
    module Assertions
      module_function

      # Validate partial match (expected keys/values are subset of actual)
      def validate_partial_match(actual, expected, field_name)
        if actual.nil?
          { passed: false, actual: nil, message: "Expected #{field_name} to be present" }
        elsif expected.all? { |k, v| actual[k] == v }
          { passed: true, actual: actual }
        else
          {
            passed: false,
            actual: actual,
            message: "expected #{field_name} to include #{expected.inspect}\ngot: #{actual.inspect}",
          }
        end
      end

      # Validate exact match (deep comparison with symbolized keys)
      def validate_exact_match(actual, expected, field_name)
        actual_sym = actual&.to_h&.deep_symbolize_keys || {}
        expected_sym = expected.deep_symbolize_keys

        if actual_sym == expected_sym
          { passed: true, actual: actual_sym }
        else
          {
            passed: false,
            actual: actual,
            message: "expected #{field_name} to equal #{expected.inspect}, got #{actual || 'nothing'}",
          }
        end
      end

      # Validate key doesn't exist
      def validate_key_absent(hash, key, field_name)
        hash ||= {}
        if hash.key?(key)
          { passed: false, actual: hash, message: "Expected #{field_name} #{key.inspect} to not exist" }
        else
          { passed: true, actual: hash }
        end
      end

      # Validate deferred props (nil = any present, Symbol/String = group exists, Hash = group has keys)
      def validate_deferred_props(actual, expected)
        actual ||= {}

        if expected.nil?
          if actual.present?
            { passed: true, actual: actual }
          else
            { passed: false, actual: actual, message: 'Expected deferred props to be present' }
          end
        elsif expected.is_a?(Hash)
          expected.each do |group, keys|
            actual_keys = actual[group] || []
            expected_sorted = keys.map(&:to_s).sort
            actual_sorted = actual_keys.map(&:to_s).sort

            unless actual_sorted == expected_sorted
              return {
                passed: false,
                actual: actual,
                message: "Expected deferred group #{group.inspect} to have keys #{keys.inspect}, " \
                         "got #{actual_keys.inspect}",
              }
            end
          end
          { passed: true, actual: actual }
        elsif actual.key?(expected)
          # Single group name (symbol or string)
          { passed: true, actual: actual }
        else
          { passed: false, actual: actual, message: "Expected deferred group #{expected.inspect} to exist" }
        end
      end
    end

    # Shared helper methods for both RSpec and Minitest
    module Helpers
      def inertia
        InertiaRails::Testing.current_response
      end

      # Perform a partial reload requesting only specified props
      def inertia_reload_only(*props)
        partial_headers = {
          'X-Inertia' => 'true',
          'X-Inertia-Partial-Data' => props.map(&:to_s).join(','),
          'X-Inertia-Partial-Component' => inertia.component,
        }
        get request.fullpath, headers: partial_headers
      end

      # Perform a partial reload excluding specified props
      def inertia_reload_except(*props)
        partial_headers = {
          'X-Inertia' => 'true',
          'X-Inertia-Partial-Except' => props.map(&:to_s).join(','),
          'X-Inertia-Partial-Component' => inertia.component,
        }
        get request.fullpath, headers: partial_headers
      end

      # Load deferred props by group (or all if no group specified)
      def inertia_load_deferred_props(group = nil)
        deferred = inertia&.deferred_props || {}
        keys = group ? (deferred[group] || []) : deferred.values.flatten
        return if keys.empty?

        inertia_reload_only(*keys)
      end
    end
  end
end
