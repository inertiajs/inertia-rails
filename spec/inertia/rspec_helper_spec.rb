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
  def puts(thing)
  end
end

RSpec.describe InertiaRails::RSpec, type: :request do
  describe 'correctly set up inertia tests with inertia: true', inertia: true do
    context 'with props' do
      before { get props_path }

      it 'has props' do
        expect_inertia.to have_exact_props({name: 'Brandon', sport: 'hockey'})
      end

      it 'includes props' do
        expect_inertia.to include_props({sport: 'hockey'})
      end

      it 'can retrieve props' do
        expect(inertia.props[:name]).to eq 'Brandon'
      end
    end

    context 'with view data' do
      before { get view_data_path }

      it 'has view data' do
        expect_inertia.to have_exact_view_data({name: 'Brian', sport: 'basketball'})
      end

      it 'includes view data' do
        expect_inertia.to include_view_data({sport: 'basketball'})
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

  describe 'inertia tests missing the inertia: true flag' do
    before { get component_path }

    it 'warns you to add inertia: true' do
      expect { expect_inertia }.to raise_error(/inertia: true/)
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
      begin
        original_stderr = $stderr
        fake_std_err    = FakeStdErr.new
        $stderr         = fake_std_err
        expect_inertia
        warn_message = 'WARNING: the test never created an Inertia renderer. Maybe the code wasn\'t able to reach a `render inertia:` call? If this was intended, or you don\'t want to see this message, set ::RSpec.configuration.inertia[:skip_missing_renderer_warnings] = true'
        expect(fake_std_err.messages[0].chomp).to(eq(warn_message))
      ensure
        $std_err = original_stderr
      end
    end

    context 'with the :skip_missing_renderer_warnings setting set to true' do
      before {
        @original = ::RSpec.configuration.inertia[:skip_missing_renderer_warnings]
        ::RSpec.configuration.inertia[:skip_missing_renderer_warnings] = true
      }
      after {
        ::RSpec.configuration.inertia[:skip_missing_renderer_warnings] = @original
      }
      it 'skips the warning' do
        begin
          original_stderr = $stderr
          fake_std_err    = FakeStdErr.new
          $stderr         = fake_std_err
          expect_inertia
          expect(fake_std_err.messages).to be_empty
        ensure
          $std_err = original_stderr
        end
      end
    end
  end
end
