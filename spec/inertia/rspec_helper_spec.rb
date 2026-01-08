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
      expect(inertia).to be_inertia_response
    end

    it 'does not match when response is not an Inertia response' do
      get non_inertiafied_path
      expect(inertia).not_to be_inertia_response
    end

    it 'fails with helpful message when given unexpected type' do
      get props_path
      # Wrong type should not match (even when inertia response exists)
      expect(response).not_to be_inertia_response

      # Verify the failure message is helpful
      expect do
        expect(response).to be_inertia_response
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /expected `inertia` helper/)
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
            property_b: 'this value',
          },
          property_c: 'some other value'
        )
      end
    end
  end

  describe 'block-based matchers' do
    context 'with props' do
      before { get props_path }

      it 'passes when block returns true' do
        expect(inertia).to(have_props { |props| props[:name] == 'Brandon' })
      end

      it 'fails when block returns false' do
        expect do
          expect(inertia).to(have_props { |props| props[:name] == 'Wrong' })
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /props block validation failed/)
      end

      it 'works with negation' do
        expect(inertia).not_to(have_props { |props| props[:name] == 'NotBrandon' })
      end

      it 'allows complex validation logic' do
        expect(inertia).to(have_props do |props|
          props[:name].is_a?(String) && props[:sport].present?
        end)
      end
    end

    context 'with view_data' do
      before { get view_data_path }

      it 'passes when block returns true' do
        expect(inertia).to(have_view_data { |view_data| view_data[:name] == 'Brian' })
      end

      it 'works with negation' do
        expect(inertia).not_to(have_view_data { |view_data| view_data[:name] == 'NotBrian' })
      end
    end

    context 'with flash' do
      before { get render_with_inertia_flash_method_path }

      it 'passes when block returns true' do
        expect(inertia).to(have_flash { |flash| flash[:success] == 'Item saved!' })
      end

      it 'works with negation' do
        expect(inertia).not_to(have_flash { |flash| flash[:nonexistent].present? })
      end
    end
  end

  describe 'negative matchers' do
    before { get props_path }

    describe 'have_no_prop' do
      it 'passes when prop does not exist' do
        expect(inertia).to have_no_prop(:nonexistent)
      end

      it 'fails when prop exists' do
        expect(inertia).not_to have_no_prop(:name)
      end
    end

    describe 'negated have_props' do
      it 'passes when props do not match' do
        expect(inertia).not_to have_props(name: 'NotBrandon')
      end

      it 'passes when key does not exist' do
        expect(inertia).not_to have_props(nonexistent: 'value')
      end
    end

    describe 'negated have_exact_props' do
      it 'passes when props do not match exactly' do
        expect(inertia).not_to have_exact_props(name: 'Brandon')
      end
    end
  end

  describe 'negative view_data matchers' do
    before { get view_data_path }

    describe 'have_no_view_data' do
      it 'passes when view_data key does not exist' do
        expect(inertia).to have_no_view_data(:nonexistent)
      end

      it 'fails when view_data key exists' do
        expect(inertia).not_to have_no_view_data(:name)
      end
    end

    describe 'negated have_view_data' do
      it 'passes when view_data does not match' do
        expect(inertia).not_to have_view_data(name: 'NotBrian')
      end
    end

    describe 'negated have_exact_view_data' do
      it 'passes when view_data does not match exactly' do
        expect(inertia).not_to have_exact_view_data(name: 'Brian')
      end
    end
  end

  describe 'negative flash matchers' do
    before { get render_with_inertia_flash_method_path }

    describe 'have_no_flash' do
      it 'passes when flash key does not exist' do
        expect(inertia).to have_no_flash(:nonexistent)
      end

      it 'fails when flash key exists' do
        expect(inertia).not_to have_no_flash(:success)
      end
    end

    describe 'negated have_flash' do
      it 'passes when flash does not match' do
        expect(inertia).not_to have_flash(success: 'wrong_value')
      end
    end

    describe 'negated have_exact_flash' do
      it 'passes when flash does not match exactly' do
        expect(inertia).not_to have_exact_flash(success: 'Item saved!')
      end
    end
  end

  describe 'negated deferred props matchers' do
    context 'without deferred props' do
      before { get props_path }

      it 'passes negated have_deferred_props' do
        expect(inertia).not_to have_deferred_props
      end
    end

    context 'with deferred props' do
      before { get deferred_props_path }

      it 'passes negated have_deferred_props for nonexistent prop' do
        expect(inertia).not_to have_deferred_props(:nonexistent)
      end

      it 'passes negated have_deferred_props when prop not in group' do
        # :sport is in :other group, not :default
        expect(inertia).not_to have_deferred_props(:sport)
        expect(inertia).not_to have_deferred_props(:level, group: :other)
      end
    end
  end

  describe 'flash matchers' do
    context 'with flash data' do
      before { get render_with_inertia_flash_method_path }

      it 'has flash' do
        expect(inertia).to have_flash(success: 'Item saved!')
      end

      it 'has exact flash' do
        expect(inertia).to have_exact_flash(success: 'Item saved!', notice: 'Changes applied')
      end

      it 'can retrieve flash directly' do
        expect(inertia.flash[:success]).to eq 'Item saved!'
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

      it 'has specific deferred props in default group' do
        expect(inertia).to have_deferred_props(:level)
        expect(inertia).to have_deferred_props(:level, :grit)
      end

      it 'has specific deferred props in explicit group' do
        expect(inertia).to have_deferred_props(:sport, group: :other)
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

  describe 'partial reload helpers' do
    describe 'inertia_reload_only' do
      it 'reloads only specified props' do
        get deferred_props_path

        # Initially deferred props are not in props
        expect(inertia.props[:level]).to be_nil
        expect(inertia.props[:grit]).to be_nil

        # Reload only the level prop
        inertia_reload_only(:level)

        # Now level should be present
        expect(inertia.props[:level]).to eq 'worse than he believes'
        # grit was not requested so it should not be present
        expect(inertia.props[:grit]).to be_nil
      end

      it 'reloads multiple props at once' do
        get deferred_props_path

        inertia_reload_only(:level, :grit)

        expect(inertia.props[:level]).to eq 'worse than he believes'
        expect(inertia.props[:grit]).to eq 'intense'
      end
    end

    describe 'inertia_reload_except' do
      it 'reloads all props except specified ones' do
        get deferred_props_path

        # Reload all props except level
        inertia_reload_except(:level)

        # name and grit should be present, but not level
        expect(inertia.props[:name]).to eq 'Brian'
        expect(inertia.props[:grit]).to eq 'intense'
        expect(inertia.props[:level]).to be_nil
      end
    end

    describe 'inertia_load_deferred_props' do
      it 'loads deferred props from a specific group' do
        get deferred_props_path

        # Load only the 'other' group (contains :sport)
        inertia_load_deferred_props('other')

        expect(inertia.props[:sport]).to eq 'basketball'
        # Props from default group should not be loaded
        expect(inertia.props[:level]).to be_nil
      end

      it 'loads all deferred props when no group specified' do
        get deferred_props_path

        # Load all deferred props
        inertia_load_deferred_props

        expect(inertia.props[:sport]).to eq 'basketball'
        expect(inertia.props[:level]).to eq 'worse than he believes'
        expect(inertia.props[:grit]).to eq 'intense'
      end

      it 'does nothing when group does not exist' do
        get deferred_props_path

        original_props = inertia.props.dup
        inertia_load_deferred_props(:nonexistent_group)

        # Props should remain unchanged
        expect(inertia.props).to eq original_props
      end
    end
  end
end
