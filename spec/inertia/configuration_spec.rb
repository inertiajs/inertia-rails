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

    context 'multithreaded' do
      it 'does not share the version across threads' do
        thread1_waits = true
        thread2_waits = true

        thread1 = Thread.new do
          sleep 0.1 while thread1_waits

          InertiaRails.configure do |config|
            config.version = 'The original version'
          end
          get long_request_test_path, headers: {'X-Inertia' => true, 'HTTP_X_INERTIA_VERSION' => 'The original version'}

          expect(subject).to eq 'The original version'
        end

        thread2 = Thread.new do
          sleep 0.1 while thread2_waits

          InertiaRails.configure do |config|
            config.version = 'Not the original version'
          end
        end

        thread1_waits = false
        sleep 0.5
        thread2_waits = false

        # Make sure that both threads finish before the block returns
        thread1.join
        thread2.join
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
        get empty_test_path
      end

      it { is_expected.to render_template 'inertia' }
      it { is_expected.to render_template 'testing' }
      it { is_expected.not_to render_template 'application' }
    end

    context 'multithreaded' do
      it 'does not share configuration between threads' do
        start_thread1 = false
        start_thread2 = false

        thread1 = Thread.new do
          sleep 0.1 unless start_thread1

          get long_request_test_path
          expect(subject).not_to render_template 'testing'
          expect(subject).to render_template 'application'
        end

        thread2 = Thread.new do
          sleep 0.1 unless start_thread2

          InertiaRails.configure do |config|
            config.layout = 'testing'
          end
        end

        start_thread1 = true
        sleep 0.5
        start_thread2 = true

        # Make sure that both threads finish before the block returns
        thread1.join
        thread2.join
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
