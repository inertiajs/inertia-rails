# frozen_string_literal: true

require_relative '../../lib/inertia_rails/rspec'

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

RSpec.describe InertiaRails::RSpec, type: :request do
  describe 'auto-detected inertia tests (no flag needed)' do
    context 'with props' do
      before { get props_path }

      it 'has props' do
        expect_inertia.to have_exact_props({ name: 'Brandon', sport: 'hockey' })
      end

      it 'has props using have_props matcher' do
        expect_inertia.to have_props({ sport: 'hockey' })
      end

      it 'can retrieve props with symbol keys' do
        expect(inertia.props[:name]).to eq 'Brandon'
      end

      it 'can retrieve props with string keys (indifferent access)' do
        expect(inertia.props['name']).to eq 'Brandon'
      end
    end

    context 'with props during sequential request' do
      before { get props_path, headers: { 'X-Inertia': true } }

      it 'has props (symbol keys work)' do
        expect_inertia.to have_exact_props({ name: 'Brandon', sport: 'hockey' })
      end

      it 'has props (string keys also work)' do
        expect_inertia.to have_exact_props({ 'name' => 'Brandon', 'sport' => 'hockey' })
      end

      it 'can retrieve props with symbol keys' do
        expect(inertia.props[:name]).to eq 'Brandon'
      end

      it 'can retrieve props with string keys (indifferent access)' do
        expect(inertia.props['name']).to eq 'Brandon'
      end
    end

    context 'with view data' do
      before { get view_data_path }

      it 'has view data' do
        expect_inertia.to have_exact_view_data({ name: 'Brian', sport: 'basketball' })
      end

      it 'has view data using have_view_data matcher' do
        expect_inertia.to have_view_data({ sport: 'basketball' })
      end

      it 'can retrieve view data' do
        expect(inertia.view_data[:name]).to eq 'Brian'
      end
    end

    context 'with component name' do
      before { get component_path }

      it 'has the component name' do
        expect_inertia.to render_component 'TestComponent'
      end

      it 'can retrieve the component name' do
        expect(inertia.component).to eq 'TestComponent'
      end
    end
  end

  describe 'deprecated inertia: true flag', inertia: true do
    before { get props_path }

    it 'still works for backwards compatibility' do
      expect_inertia.to have_exact_props({ name: 'Brandon', sport: 'hockey' })
    end
  end

  describe 'deprecated matchers' do
    before { get props_path }

    it 'include_props still works but is deprecated' do
      expect_inertia.to include_props({ sport: 'hockey' })
    end
  end

  describe 'be_inertia_response matcher' do
    it 'matches when response is an Inertia response' do
      get props_path
      expect(response).to be_inertia_response
    end

    it 'does not match when response is not an Inertia response' do
      get non_inertiafied_path
      expect(response).not_to be_inertia_response
    end
  end

  describe 'expecting inertia on a non inertia route', inertia: true do
    before { get non_inertiafied_path }

    it 'does not complain about test helpers' do
      expect { expect_inertia }.not_to raise_error
    end

    # h/t for this technique:
    # https://blog.arkency.com/testing-deprecations-warnings-with-rspec/
    it 'warns that the renderer was never created' do
      original_stderr = $stderr
      fake_std_err    = FakeStdErr.new
      $stderr         = fake_std_err
      expect_inertia
      warn_message =
        'WARNING: the test never created an Inertia renderer. ' \
        "Maybe the code wasn't able to reach a `render inertia:` call? If this was intended, " \
        "or you don't want to see this message, set " \
        '::RSpec.configuration.inertia[:skip_missing_renderer_warnings] = true'
      expect(fake_std_err.messages[0].chomp).to(eq(warn_message))
    ensure
      $stderr = original_stderr
    end

    context 'with the :skip_missing_renderer_warnings setting set to true' do
      before do
        @original = RSpec.configuration.inertia[:skip_missing_renderer_warnings]
        RSpec.configuration.inertia[:skip_missing_renderer_warnings] = true
      end
      after do
        RSpec.configuration.inertia[:skip_missing_renderer_warnings] = @original
      end
      it 'skips the warning' do
        original_stderr = $stderr
        fake_std_err    = FakeStdErr.new
        $stderr         = fake_std_err
        expect_inertia
        expect(fake_std_err.messages).to be_empty
      ensure
        $stderr = original_stderr
      end
    end
  end

  describe '.have_exact_props' do
    context 'when shared props are wrapped in a callable' do
      it 'compares props with either string or symbol keys' do
        get lamda_shared_props_path

        expect_inertia.to have_exact_props(
          someProperty: {
            property_a: 'some value',
            property_b: 'this value'
          },
          property_c: 'some other value'
        )
      end
    end
  end

  describe 'flash matchers' do
    context 'with flash data' do
      before { get render_with_inertia_flash_method_path }

      it 'has flash' do
        expect(inertia).to have_flash(foo: 'bar')
      end

      it 'has exact flash' do
        expect(inertia).to have_exact_flash(foo: 'bar', baz: 'qux')
      end

      it 'can retrieve flash directly' do
        expect(inertia.flash[:foo]).to eq 'bar'
      end
    end

    context 'with flash.now data' do
      before { get render_with_inertia_flash_now_path }

      it 'has flash' do
        expect(inertia).to have_flash(temporary: 'current request only')
      end
    end
  end

  describe 'deferred props matchers' do
    context 'with deferred props' do
      before { get deferred_props_path }

      it 'has deferred props' do
        expect(inertia).to have_deferred_props
      end

      it 'has specific deferred group' do
        expect(inertia).to have_deferred_props('default')
        expect(inertia).to have_deferred_props(:other)
      end

      it 'has deferred group with specific keys' do
        expect(inertia).to have_deferred_props('default' => %w[level grit])
        expect(inertia).to have_deferred_props(other: ['sport'])
      end

      it 'can retrieve deferred props directly' do
        expect(inertia.deferred_props[:default]).to include(:level, :grit)
      end

      it 'does not include deferred props in regular props on first load' do
        expect(inertia.props[:sport]).to be_nil
        expect(inertia.props[:level]).to be_nil
      end
    end
  end
end
