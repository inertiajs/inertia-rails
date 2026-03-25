# frozen_string_literal: true

RSpec.describe 'using inertia share when rendering views', type: :request do
  subject { JSON.parse(response.body)['props'].deep_symbolize_keys }

  context 'using inertia share' do
    let(:props) do
      { name: 'Brandon', sport: 'hockey', position: 'center', number: 29, a_hash: 'also works',
        nested: { user: { name: 'Brandon', role: 'admin' }, settings: { theme: 'dark' } }, }
    end
    before { get share_path, headers: { 'X-Inertia' => true } }

    it { is_expected.to eq props }
  end

  context 'inertia share across requests' do
    before do
      get share_path, headers: { 'X-Inertia' => true }
      get empty_test_path, headers: { 'X-Inertia' => true }
    end

    it { is_expected.to eq({}) }
  end

  context 'using inertia share in subsequent requests' do
    let(:props) do
      { name: 'Brandon', sport: 'hockey', position: 'center', number: 29, a_hash: 'also works',
        nested: { user: { name: 'Brandon', role: 'admin' }, settings: { theme: 'dark' } }, }
    end

    before do
      get share_path, headers: { 'X-Inertia' => true }
      get share_path, headers: { 'X-Inertia' => true }
    end

    it { is_expected.to eq props }
  end

  context 'using inertia share with inheritance' do
    let(:props) do
      { name: 'No Longer Brandon', sport: 'hockey', position: 'center', number: 29, a_hash: 'also works',
        nested: { user: { name: 'Brandon', role: 'admin' }, settings: { theme: 'dark' } }, }
    end

    before do
      get share_with_inherited_path, headers: { 'X-Inertia' => true }
    end

    it { is_expected.to eq props }
  end

  context 'with errors' do
    let(:props) do
      { name: 'Brandon', sport: 'hockey', position: 'center', number: 29, a_hash: 'also works',
        nested: { user: { name: 'Brandon', role: 'admin' }, settings: { theme: 'dark' } }, }
    end
    let(:errors) { 'rearview mirror is present' }
    before do
      allow_any_instance_of(ActionDispatch::Request).to receive(:session) {
        spy(ActionDispatch::Request::Session).tap do |spy|
          allow(spy).to receive(:[])
          allow(spy).to receive(:[]).with(:inertia_errors).and_return(errors)
        end
      }
      get share_path, headers: { 'X-Inertia' => true }
    end

    it { is_expected.to eq props.merge({ errors: errors }) }
  end

  describe 'sharedProps metadata' do
    let(:page) { JSON.parse(response.body) }
    let(:headers) { { 'X-Inertia' => true } }

    it 'includes top-level keys from multiple inertia_share calls' do
      get share_path, headers: headers

      expect(page['sharedProps']).to match_array(%w[name sport a_hash position number nested])
    end

    it 'includes shared lambda prop keys but not page-specific keys' do
      get lamda_shared_props_path, headers: headers

      expect(page['sharedProps']).to eq(%w[someProperty])
      expect(page['props']).to have_key('property_c')
    end

    it 'includes shared key even when page props override it' do
      get merge_shared_path, headers: headers

      expect(page['sharedProps']).to eq(%w[nested])
    end

    it 'includes shared once prop keys' do
      get shared_once_props_path, headers: headers

      expect(page['sharedProps']).to eq(%w[shared_cached])
    end

    it 'includes shared deferred prop keys' do
      get shared_deferred_props_path, headers: headers

      expect(page['sharedProps']).to eq(%w[grit])
    end

    it 'omits sharedProps when there are no shared props' do
      get empty_test_path, headers: headers

      expect(page).not_to have_key('sharedProps')
    end

    context 'when disabled' do
      with_inertia_config expose_shared_prop_keys: false

      it 'does not include sharedProps' do
        get share_path, headers: headers

        expect(page).not_to have_key('sharedProps')
      end
    end
  end

  describe 'deep or shallow merging shared data' do
    context 'with default settings (shallow merge)' do
      describe 'shallow merging by default' do
        let(:props) { { nested: { assists: 200 } } }
        before { get merge_shared_path, headers: { 'X-Inertia' => true } }
        it { is_expected.to eq props }
      end

      context 'with deep merge added to the renderer' do
        let(:props) { { nested: { goals: 100, assists: 300 } } }
        before { get deep_merge_shared_path, headers: { 'X-Inertia' => true } }
        it { is_expected.to eq props }
      end
    end

    context 'with deep merge configured as the default' do
      with_inertia_config deep_merge_shared_data: true

      describe 'deep merging by default' do
        let(:props) { { nested: { goals: 100, assists: 200 } } }
        before { get merge_shared_path, headers: { 'X-Inertia' => true } }
        it { is_expected.to eq props }
      end

      describe 'overriding deep merge in a specific action' do
        let(:props) { { nested: { assists: 200 } } }
        before { get shallow_merge_shared_path, headers: { 'X-Inertia' => true } }
        it { is_expected.to eq props }
      end
    end

    context 'merging with instance props' do
      let(:props) { { nested: { points: 100, rebounds: 10 } } }
      before { get merge_instance_props_path, headers: { 'X-Inertia' => true } }
      it { is_expected.to eq props }
    end
  end
end
