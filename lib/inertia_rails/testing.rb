# frozen_string_literal: true

module InertiaRails
  module Testing
    thread_mattr_accessor :current_response

    module RendererTestingPatch
      def new(component, controller, request, response, render, **options)
        wrapped = TestResponse.new.wrap_render(render)
        InertiaRails::Testing.current_response = wrapped
        super(component, controller, request, response, wrapped, **options)
      end
    end

    def self.install!
      return if @installed

      InertiaRails::Renderer.singleton_class.prepend(RendererTestingPatch)
      @installed = true
    end

    class TestResponse
      attr_reader :view_data, :props, :component, :flash, :deferred_props

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
          page = params[:locals][:page] || {}
        else
          # Sequential Inertia request
          @view_data = {}
          page = JSON.parse(params[:json])
        end

        page = page.with_indifferent_access
        @props = (page[:props] || {}).with_indifferent_access
        @component = page[:component]
        @flash = (page[:flash] || {}).with_indifferent_access
        @deferred_props = (page[:deferredProps] || {}).with_indifferent_access
      end
    end

    module Assertions
      class << self
        def validate_with_block(inertia, field, &block)
          actual = inertia&.public_send(field)
          negated = "expected #{field} block to return false"

          if block.call(actual)
            { passed: true, negated_message: negated }
          else
            { passed: false, message: "#{field} block validation failed", negated_message: negated }
          end
        end

        def validate_partial_match(inertia, field, expected)
          actual = inertia&.public_send(field)
          negated = "expected #{field} not to include #{expected.inspect}"

          return { passed: false, message: "expected #{field} to be present", negated_message: negated } if actual.nil?

          actual_sym = actual.to_h.deep_symbolize_keys
          expected_sym = expected.deep_symbolize_keys

          if expected_sym.all? { |k, v| actual_sym[k] == v }
            { passed: true, negated_message: negated }
          else
            {
              passed: false,
              message: "expected #{field} to include #{expected.inspect}\ngot: #{actual.inspect}",
              negated_message: negated,
            }
          end
        end

        def validate_exact_match(inertia, field, expected)
          actual = inertia&.public_send(field)
          actual_sym = actual&.to_h&.deep_symbolize_keys || {}
          expected_sym = expected.deep_symbolize_keys
          negated = "expected #{field} not to equal #{expected.inspect}"

          if actual_sym == expected_sym
            { passed: true, negated_message: negated }
          else
            {
              passed: false,
              message: "expected #{field} to equal #{expected.inspect}, got #{actual || 'nothing'}",
              negated_message: negated,
            }
          end
        end

        def validate_key_absent(inertia, field, key)
          actual = inertia&.public_send(field) || {}
          negated = "expected #{field} to have key #{key.inspect}"

          if actual.key?(key)
            { passed: false, message: "expected #{field} not to have key #{key.inspect}",
              negated_message: negated, }
          else
            { passed: true, negated_message: negated }
          end
        end

        def validate_component(inertia, expected)
          actual = inertia&.component
          negated = "expected component not to be #{expected.inspect}"

          if actual == expected
            { passed: true, negated_message: negated }
          else
            {
              passed: false,
              message: "expected component to be #{expected.inspect}, got #{actual.nil? ? 'nothing' : actual.inspect}",
              negated_message: negated,
            }
          end
        end

        def validate_inertia_response(inertia)
          negated = 'expected response not to be an Inertia response'

          unless inertia.nil? || inertia.is_a?(InertiaRails::Testing::TestResponse)
            return {
              passed: false,
              message: "expected `inertia` helper, got #{inertia.class}. " \
                       'Use the `inertia` helper instead of passing the response directly.',
              negated_message: negated,
            }
          end

          if inertia&.component.present?
            { passed: true, negated_message: negated }
          else
            { passed: false, message: 'expected an Inertia response', negated_message: negated }
          end
        end

        def validate_deferred_props(inertia, *expected_keys, group: nil)
          actual = inertia&.deferred_props || {}

          if expected_keys.empty?
            negated = 'expected no deferred props to be present'
            return { passed: true, negated_message: negated } if actual.present?

            return { passed: false, message: 'expected deferred props to be present', negated_message: negated }
          end

          group ||= :default
          expected_sorted = expected_keys.map(&:to_s).sort
          actual_keys = actual[group] || actual[group.to_s] || []
          actual_sorted = actual_keys.map(&:to_s).sort
          negated = "expected #{expected_keys.inspect} not to be deferred in group #{group.inspect}"

          missing = expected_sorted - actual_sorted
          if missing.empty?
            { passed: true, negated_message: negated }
          else
            {
              passed: false,
              message: "expected #{missing.map(&:to_sym).inspect} to be deferred in group #{group.inspect}, " \
                       "but group has #{actual_keys.inspect}",
              negated_message: negated,
            }
          end
        end
      end
    end

    module Helpers
      def inertia
        response = InertiaRails::Testing.current_response
        validate_inertia_helper_type!(response)
        response
      end

      def inertia_reload_only(*props)
        partial_headers = {
          'X-Inertia' => 'true',
          'X-Inertia-Partial-Data' => props.map(&:to_s).join(','),
          'X-Inertia-Partial-Component' => inertia.component,
        }
        get request.fullpath, headers: partial_headers
      end

      def inertia_reload_except(*props)
        partial_headers = {
          'X-Inertia' => 'true',
          'X-Inertia-Partial-Except' => props.map(&:to_s).join(','),
          'X-Inertia-Partial-Component' => inertia.component,
        }
        get request.fullpath, headers: partial_headers
      end

      def inertia_load_deferred_props(group = nil)
        deferred = inertia&.deferred_props || {}
        keys = group ? (deferred[group] || []) : deferred.values.flatten
        return if keys.empty?

        inertia_reload_only(*keys)
      end

      private

      def validate_inertia_helper_type!(response)
        return if response.nil? || response.is_a?(InertiaRails::Testing::TestResponse)

        raise ArgumentError,
              "Inertia test helpers expect `inertia` to return TestResponse, got #{response.class}. " \
              'Ensure you are using the inertia test helpers correctly.'
      end
    end
  end
end
