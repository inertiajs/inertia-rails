RSpec.describe 'using inertia share when rendering views', type: :request do
  subject { JSON.parse(response.body)['props'].deep_symbolize_keys }

  context 'using inertia share' do
    let(:props) { {name: 'Brandon', sport: 'hockey', position: 'center', number: 29} }
    before { get share_path, headers: {'X-Inertia' => true} }

    it { is_expected.to eq props }
  end

  context 'inertia share across requests' do
    before do
      get share_path, headers: {'X-Inertia' => true}
      get empty_test_path, headers: {'X-Inertia' => true}
    end

    it { is_expected.to eq({}) }
  end

  context 'using inertia share in subsequent requests' do
    let(:props) { {name: 'Brandon', sport: 'hockey', position: 'center', number: 29} }

    before do
      get share_path, headers: {'X-Inertia' => true}
      get share_path, headers: {'X-Inertia' => true}
    end

    it { is_expected.to eq props }
  end

  context 'using inertia share with inheritance' do
    let(:props) { {name: 'No Longer Brandon', sport: 'hockey', position: 'center', number: 29} }

    before do
      get share_with_inherited_path, headers: {'X-Inertia' => true}
    end

    it { is_expected.to eq props }
  end

  context 'with errors' do
    let(:props) { {name: 'Brandon', sport: 'hockey', position: 'center', number: 29} }
    let(:errors) { 'rearview mirror is present' }
    before {
      allow_any_instance_of(ActionDispatch::Request).to receive(:session) {
        spy(ActionDispatch::Request::Session).tap do |spy|
          allow(spy).to receive(:[])
          allow(spy).to receive(:[]).with(:inertia_errors).and_return(errors)
        end
      }
      get share_path, headers: {'X-Inertia' => true}
    }

    it { is_expected.to eq props.merge({ errors: errors }) }
  end

  context 'multithreaded intertia share' do
    let(:props) { { name: 'Michael', has_goat_status: true } }
    it 'is expected to render props even when another thread shares Inertia data' do
      start_thread1 = false
      start_thread2 = false

      thread1 = Thread.new do
        sleep 0.1 until start_thread1

        get share_multithreaded_path, headers: {'X-Inertia' => true}
        expect(subject).to eq props
      end

      thread2 = Thread.new do
        sleep 0.1 until start_thread2

        # Would prefer to make this a second get request, but RSpec will overwrite
        # the @response variable if another request is made in the second thread.
        # This simulates the relevant effects of another call to a different
        # controller with different values for inertia_share
        InertiaRails.reset!
        InertiaRails.share(name: 'Brian', has_goat_status: false)
      end

      # Thread 1 starts. The controller method runs inertia_share, then sleeps.
      # Thread 2 then modifies the shared inertia data before Thread 1 stops sleeping
      start_thread1 = true
      sleep 0.5
      start_thread2 = true

      # Make sure that both threads finish before the block returns
      thread1.join
      thread2.join
    end

    it 'is expected not to leak shared data across requests' do
      begin
        get share_multithreaded_error_path, headers: {'X-Inertia' => true}
      rescue Exception
      end

      expect(InertiaRails.shared_plain_data).to be_empty
      expect(InertiaRails.shared_blocks).to be_empty
    end
  end

  describe 'deep or shallow merging shared data' do
    context 'with default settings (shallow merge)' do
      describe 'shallow merging by default' do
        let(:props) { { nested: { assists: 200 } } }
        before { get merge_shared_path, headers: {'X-Inertia' => true} }
        it { is_expected.to eq props }
      end

      context 'with deep merge added to the renderer' do
        let(:props) { { nested: { goals: 100, assists: 300 } } }
        before { get deep_merge_shared_path, headers: {'X-Inertia' => true} }
        it { is_expected.to eq props }
      end
    end

    context 'with deep merge configured as the default' do
      before {
        InertiaRails.configure { |config| config.deep_merge_shared_data = true }
      }
      after {
        InertiaRails.configure { |config| config.deep_merge_shared_data = false }
      }
      describe 'deep merging by default' do
        let(:props) { { nested: { goals: 100, assists: 200 } } }
        before { get merge_shared_path, headers: {'X-Inertia' => true} }
        it { is_expected.to eq props }
      end

      describe 'overriding deep merge in a specific action' do
        let(:props) { { nested: { assists: 200 } } }
        before { get shallow_merge_shared_path, headers: {'X-Inertia' => true} }
        it { is_expected.to eq props }
      end
    end

    context 'merging with instance props' do
      let(:props) { { nested: { points: 100, rebounds: 10 } } }
      before { get merge_instance_props_path, headers: {'X-Inertia' => true} }
      it { is_expected.to eq props }
    end
  end
end
