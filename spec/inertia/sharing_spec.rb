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

  context 'when multithreaded with shared data' do
    let(:props) { { name: 'Michael', has_goat_status: true } }

      it 'is expected to not share data from other requests' do
        threads = []
        threads << Thread.new do
          # Its takes one second
          get share_multithreaded_path, headers: {'X-Inertia' => true}
          body = response.body.dup
          props = JSON.parse(body)['props'].deep_symbolize_keys
          expect(props).to eq({ name: 'Michael', has_goat_status: true })
        end
        threads << Thread.new do
          # Its take half a second
          get share_without_name_path, headers: {'X-Inertia' => true}
          body = response.body.dup
          props = JSON.parse(body)['props'].deep_symbolize_keys
          expect(props).to eq({ someGroupsControllerData: true })
        end


        threads.each(&:join)
      end
  end

  context 'when raises an exception' do
    it 'is expected not to leak shared data across requests' do
      begin
        get share_multithreaded_error_path, headers: {'X-Inertia' => true}
      rescue Exception
      end

      get share_path, headers: {'X-Inertia' => true}

      is_expected.to eq({name: 'Brandon', sport: 'hockey', position: 'center', number: 29})
    end
  end

  context 'using inertia share in redirected requests' do
    let(:props) { {name: 'Brandon', sport: 'hockey', position: 'center', number: 29} }

    before do
      post redirect_to_share_test_path, headers: {'X-Inertia' => true}
      expect(response).to be_redirect

      get response.location, headers: {'X-Inertia' => true}
    end

    it { is_expected.to eq props }
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
