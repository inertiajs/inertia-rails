RSpec.describe 'Inertia configuration', type: :request do
  after { reset_config! }

  describe "InertiaRails::Configuration" do
    it "does not allow to modify options after frozen" do
      config = InertiaRails::Configuration.default
      config.ssr_enabled = true
      expect(config.ssr_enabled).to eq true

      config.freeze
      expect { config.ssr_enabled = false }.to raise_error(FrozenError)
      expect { config.merge!(InertiaRails::Configuration.default) }.to raise_error(FrozenError)

      expect {
        merged_config = config.merge(InertiaRails::Configuration.default)
        expect(merged_config.ssr_enabled).to eq false
      }.not_to raise_error
    end

    context 'with environment variables' do
      it 'always prioritizes initialized variables' do
        with_env(
          'INERTIA_SSR_ENABLED' => 'true',
          'INERTIA_SSR_URL' => 'http://env-ssr-url:1234',
          'INERTIA_DEEP_MERGE_SHARED_DATA' => 'true'
        ) do
          config = InertiaRails::Configuration.default

          config.ssr_enabled = false

          expect(config.ssr_enabled).to eq false
          expect(config.ssr_url).to eq 'http://env-ssr-url:1234'
          expect(config.deep_merge_shared_data).to eq true
        end
      end

      it 'respects environment variables when merging defaults' do
        with_env(
          'INERTIA_SSR_ENABLED' => 'true'
        ) do
          config = InertiaRails::Configuration.default
          config.deep_merge_shared_data = true

          controller_config = InertiaRails::Configuration.new(ssr_url: 'http://ssr-url:1234')
          controller_config.with_defaults(config)

          expect(controller_config.ssr_enabled).to eq true
          expect(controller_config.ssr_url).to eq 'http://ssr-url:1234'
          expect(controller_config.deep_merge_shared_data).to eq true
        end
      end
    end
  end

  describe 'inertia_config' do
    it 'overrides the global values and ENV' do
      with_env(
        'INERTIA_SSR_URL' => 'http://env-ssr-url:1234'
      ) do
        get configuration_path

        expect(response.parsed_body.symbolize_keys).to include(
          deep_merge_shared_data: true,
          default_render: false,
          layout: 'test',
          ssr_enabled: true,
          ssr_url: 'http://localhost:7777',
          version: '2.0',
          encrypt_history: false
        )
      end
    end
  end

  describe '.version' do
    subject { JSON.parse(response.body)['version'] }

    context 'base case' do
      before { get empty_test_path, headers: {'X-Inertia' => true} }

      it { is_expected.to be_nil }
    end

    context 'version is a string' do
      before do
         InertiaRails.configure {|c| c.version = '1.0'}
         get empty_test_path, headers: {'X-Inertia' => true, 'HTTP_X_INERTIA_VERSION' => '1.0'}
      end

      it { is_expected.to eq '1.0' }
    end

    context 'version is a callable' do
      before do
        InertiaRails.configure {|c| c.version = -> {'1.0'}}
        get empty_test_path, headers: {'X-Inertia' => true, 'X-Inertia-Version' => '1.0'}
      end

      it { is_expected.to eq '1.0' }
    end

    context 'string vs float mismatches' do
      before do
        InertiaRails.configure {|c| c.version = 1.0}
        get empty_test_path, headers: {'X-Inertia' => true, 'X-Inertia-Version' => '1.0'}
      end

      it { is_expected.to eq 1.0 }
    end

    context 'with a new version' do
      before do
        InertiaRails.configure { |c| c.version = '1.0' }
      end

      context 'request in same thread' do
        before do
          get empty_test_path, headers: {'X-Inertia' => true, 'X-Inertia-Version' => '1.0'}
        end

        it { is_expected.to eq '1.0' }
      end

      context 'request in other thread' do
        before do
          Thread.new do
            get empty_test_path, headers: {'X-Inertia' => true, 'X-Inertia-Version' => '1.0'}
          end.join
        end

        it { is_expected.to eq '1.0' }
      end
    end
  end

  describe '.layout' do
    subject { response.body }

    context 'base case' do
      before { get empty_test_path }

      it { is_expected.to render_template 'inertia' }
      it { is_expected.to render_template 'application' }
    end

    context 'with a new layout' do
      before do
        InertiaRails.configure {|c| c.layout = 'testing' }
      end

      context 'request in same thread' do
        before do
          get empty_test_path
        end

        it { is_expected.to render_template 'inertia' }
        it { is_expected.to render_template 'testing' }
        it { is_expected.not_to render_template 'application' }
      end

      context 'request in other thread' do
        before do
          Thread.new do
            get empty_test_path
          end.join
        end

        it { is_expected.to render_template 'inertia' }
        it { is_expected.to render_template 'testing' }
        it { is_expected.not_to render_template 'application' }
      end

      context 'opting out of a different layout for Inertia' do
        before do
          InertiaRails.configure {|c| c.layout = true }
        end

        it 'uses default layout for controller' do
          get empty_test_path
          is_expected.to render_template 'inertia'
          is_expected.to render_template 'application'
          is_expected.not_to render_template 'testing'
        end

        it 'applies conditional layouts as needed' do
          get with_different_layout_path
          is_expected.to render_template 'inertia'
          is_expected.to render_template 'conditional'
          is_expected.not_to render_template 'application'
          is_expected.not_to render_template 'testing'
        end
      end
    end
  end
end

def reset_config!
  InertiaRails.configure do |config|
    config.version = nil
    config.layout = 'application'
  end
end
