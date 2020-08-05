RSpec.describe 'Inertia configuration', type: :request do
  after { reset_config! }

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
        get empty_test_path
      end

      it { is_expected.to render_template 'inertia' }
      it { is_expected.to render_template 'testing' }
      it { is_expected.not_to render_template 'application' }
    end
  end

end

def reset_config!
  InertiaRails.configure do |config|
    config.version = nil
    config.layout = 'application'
  end
end
