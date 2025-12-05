# frozen_string_literal: true

require_relative '../../lib/inertia_rails/minitest'

class FakeStdErr
  attr_accessor :messages

  def initialize
    @messages = []
  end

  def write(msg)
    @messages << msg
  end

  # Rails 5.0 + Ruby 2.6 require puts to be a public method
  def puts(thing); end
end

RSpec.describe InertiaRails::Minitest, type: :request do
  # Basic unit tests for the Minitest module components
  describe 'InertiaRenderWrapper' do
    let(:wrapper) { InertiaRails::Minitest::InertiaRenderWrapper.new }

    it 'initializes with nil values' do
      expect(wrapper.view_data).to be_nil
      expect(wrapper.props).to be_nil
      expect(wrapper.component).to be_nil
    end

    it 'extracts data from HTML response params' do
      params = {
        locals: {
          page: {
            props: { name: 'Brandon', sport: 'hockey' },
            component: 'TestComponent'
          },
          meta: 'test data'
        }
      }

      wrapper.call(params)

      # HashWithIndifferentAccess allows both access styles
      expect(wrapper.props[:name]).to eq 'Brandon'
      expect(wrapper.props['name']).to eq 'Brandon'
      expect(wrapper.component).to eq 'TestComponent'
      expect(wrapper.view_data[:meta]).to eq 'test data'
      expect(wrapper.view_data['meta']).to eq 'test data'
    end

    it 'allows both symbol and string key access for HTML response' do
      params = {
        locals: {
          page: {
            props: { name: 'Brandon', sport: 'hockey' },
            component: 'TestComponent'
          }
        }
      }

      wrapper.call(params)

      # Both should work thanks to HashWithIndifferentAccess
      expect(wrapper.props[:name]).to eq 'Brandon'
      expect(wrapper.props['name']).to eq 'Brandon'
      expect(wrapper.props[:sport]).to eq 'hockey'
      expect(wrapper.props['sport']).to eq 'hockey'
    end

    it 'extracts data from JSON response params' do
      json_data = {
        'props' => { 'name' => 'Brandon', 'sport' => 'hockey' },
        'component' => 'TestComponent'
      }
      params = { json: json_data.to_json }

      wrapper.call(params)

      # HashWithIndifferentAccess allows both access styles
      expect(wrapper.props[:name]).to eq 'Brandon'
      expect(wrapper.props['name']).to eq 'Brandon'
      expect(wrapper.component).to eq 'TestComponent'
      expect(wrapper.view_data).to eq({})
    end

    it 'allows both symbol and string key access for JSON response' do
      json_data = {
        'props' => { 'name' => 'Brandon', 'sport' => 'hockey' },
        'component' => 'TestComponent'
      }
      params = { json: json_data.to_json }

      wrapper.call(params)

      # Both should work thanks to HashWithIndifferentAccess
      expect(wrapper.props[:name]).to eq 'Brandon'
      expect(wrapper.props['name']).to eq 'Brandon'
      expect(wrapper.props[:sport]).to eq 'hockey'
      expect(wrapper.props['sport']).to eq 'hockey'
    end

    it 'wraps a render method' do
      render_method = double('render_method')
      wrapped = wrapper.wrap_render(render_method)

      expect(wrapped).to eq wrapper
      expect(wrapper.instance_variable_get(:@render_method)).to eq render_method
    end

    it 'calls the wrapped render method' do
      render_method = double('render_method')
      wrapper.wrap_render(render_method)

      params = {
        locals: {
          page: {
            props: { name: 'Brandon' },
            component: 'TestComponent'
          }
        }
      }

      expect(render_method).to receive(:call).with(params)
      wrapper.call(params)
    end
  end

  describe 'Configuration' do
    it 'has default configuration' do
      expect(InertiaRails::Minitest.config.skip_missing_renderer_warnings).to eq false
    end

    it 'allows configuration changes' do
      original_value = InertiaRails::Minitest.config.skip_missing_renderer_warnings

      InertiaRails::Minitest.config.skip_missing_renderer_warnings = true
      expect(InertiaRails::Minitest.config.skip_missing_renderer_warnings).to eq true

      # Restore
      InertiaRails::Minitest.config.skip_missing_renderer_warnings = original_value
    end

    it 'supports configure block' do
      original_value = InertiaRails::Minitest.config.skip_missing_renderer_warnings

      InertiaRails::Minitest.configure do |config|
        config.skip_missing_renderer_warnings = true
      end

      expect(InertiaRails::Minitest.config.skip_missing_renderer_warnings).to eq true

      # Restore
      InertiaRails::Minitest.config.skip_missing_renderer_warnings = original_value
    end
  end

  describe 'Helpers module' do
    # Create a test class to test the helpers
    let(:test_class) do
      Class.new do
        include Minitest::Assertions
        include InertiaRails::Minitest::Helpers

        # Need this for Minitest assertions to work
        attr_accessor :assertions

        def initialize
          @assertions = 0
        end

        # Mock setup/teardown from Minitest
        def self.setup_blocks
          @setup_blocks ||= []
        end

        def self.teardown_blocks
          @teardown_blocks ||= []
        end

        def self.setup(&block)
          setup_blocks << block
        end

        def self.teardown(&block)
          teardown_blocks << block
        end

        def run_setup
          self.class.setup_blocks.each { |block| instance_eval(&block) }
        end

        def run_teardown
          self.class.teardown_blocks.each { |block| instance_eval(&block) }
        end
      end
    end

    let(:test_instance) { test_class.new }

    describe '#inertia' do
      it 'returns the wrapper when set' do
        wrapper = InertiaRails::Minitest::InertiaRenderWrapper.new
        test_instance.instance_variable_set(:@_inertia_render_wrapper, wrapper)

        expect(test_instance.inertia).to eq wrapper
      end

      it 'returns nil when wrapper is not set' do
        # Suppress warnings for this test
        original_value = InertiaRails::Minitest.config.skip_missing_renderer_warnings
        InertiaRails::Minitest.config.skip_missing_renderer_warnings = true

        expect(test_instance.inertia).to be_nil

        InertiaRails::Minitest.config.skip_missing_renderer_warnings = original_value
      end

      it 'warns when wrapper is not set and warnings are enabled' do
        original_stderr = $stderr
        fake_std_err = FakeStdErr.new
        $stderr = fake_std_err

        test_instance.inertia

        warn_message = 'WARNING: the test never created an Inertia renderer. ' \
                       "Maybe the code wasn't able to reach a `render inertia:` call? If this was intended, " \
                       "or you don't want to see this message, " \
                       'set InertiaRails::Minitest.config.skip_missing_renderer_warnings = true'
        expect(fake_std_err.messages[0].chomp).to eq(warn_message)
      ensure
        $stderr = original_stderr
      end

      it 'does not warn when skip_missing_renderer_warnings is true' do
        original_value = InertiaRails::Minitest.config.skip_missing_renderer_warnings
        InertiaRails::Minitest.config.skip_missing_renderer_warnings = true

        original_stderr = $stderr
        fake_std_err = FakeStdErr.new
        $stderr = fake_std_err

        test_instance.inertia

        expect(fake_std_err.messages).to be_empty
      ensure
        $stderr = original_stderr
        InertiaRails::Minitest.config.skip_missing_renderer_warnings = original_value
      end
    end

    describe '#inertia_wrap_render' do
      it 'creates and stores a wrapper' do
        render_method = double('render_method')
        result = test_instance.inertia_wrap_render(render_method)

        expect(result).to be_a(InertiaRails::Minitest::InertiaRenderWrapper)
        expect(test_instance.instance_variable_get(:@_inertia_render_wrapper)).to eq result
      end
    end

    describe 'assertion methods' do
      let(:wrapper) { InertiaRails::Minitest::InertiaRenderWrapper.new }

      before do
        test_instance.instance_variable_set(:@_inertia_render_wrapper, wrapper)
      end

      describe '#assert_inertia_component' do
        it 'passes when component matches' do
          wrapper.call({ locals: { page: { props: {}, component: 'TestComponent' } } })

          expect {
            test_instance.assert_inertia_component('TestComponent')
          }.not_to raise_error
        end

        it 'fails when component does not match' do
          wrapper.call({ locals: { page: { props: {}, component: 'ActualComponent' } } })

          expect {
            test_instance.assert_inertia_component('ExpectedComponent')
          }.to raise_error(Minitest::Assertion, /Expected rendered inertia component/)
        end
      end

      describe '#assert_inertia_exact_props' do
        it 'passes when props match exactly' do
          wrapper.call({ locals: { page: { props: { name: 'Brandon', sport: 'hockey' }, component: 'Test' } } })

          expect {
            test_instance.assert_inertia_exact_props({ name: 'Brandon', sport: 'hockey' })
          }.not_to raise_error
        end

        it 'fails when props do not match' do
          wrapper.call({ locals: { page: { props: { name: 'Brandon' }, component: 'Test' } } })

          expect {
            test_instance.assert_inertia_exact_props({ name: 'Other' })
          }.to raise_error(Minitest::Assertion)
        end
      end

      describe '#assert_inertia_includes_props' do
        it 'passes when props include expected keys' do
          wrapper.call({ locals: { page: { props: { name: 'Brandon', sport: 'hockey', age: 30 }, component: 'Test' } } })

          expect {
            test_instance.assert_inertia_includes_props({ sport: 'hockey' })
          }.not_to raise_error
        end

        it 'fails when props do not include expected keys' do
          wrapper.call({ locals: { page: { props: { name: 'Brandon' }, component: 'Test' } } })

          expect {
            test_instance.assert_inertia_includes_props({ sport: 'hockey' })
          }.to raise_error(Minitest::Assertion, /Expected props to include key/)
        end
      end

      describe '#assert_inertia_exact_view_data' do
        it 'passes when view data matches exactly' do
          wrapper.call({ locals: { page: { props: {}, component: 'Test' }, meta: 'test', title: 'Title' } })

          expect {
            test_instance.assert_inertia_exact_view_data({ meta: 'test', title: 'Title' })
          }.not_to raise_error
        end

        it 'fails when view data does not match' do
          wrapper.call({ locals: { page: { props: {}, component: 'Test' }, meta: 'test' } })

          expect {
            test_instance.assert_inertia_exact_view_data({ meta: 'other' })
          }.to raise_error(Minitest::Assertion)
        end
      end

      describe '#assert_inertia_includes_view_data' do
        it 'passes when view data includes expected keys' do
          wrapper.call({ locals: { page: { props: {}, component: 'Test' }, meta: 'test', title: 'Title', extra: 'data' } })

          expect {
            test_instance.assert_inertia_includes_view_data({ meta: 'test', title: 'Title' })
          }.not_to raise_error
        end

        it 'fails when view data does not include expected keys' do
          wrapper.call({ locals: { page: { props: {}, component: 'Test' }, meta: 'test' } })

          expect {
            test_instance.assert_inertia_includes_view_data({ missing: 'key' })
          }.to raise_error(Minitest::Assertion, /Expected view data to include key/)
        end
      end
    end
  end
end
