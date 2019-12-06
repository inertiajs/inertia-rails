RSpec.describe 'using inertia share when rendering views', type: :request do
  subject { JSON.parse(response.body)['props'].symbolize_keys }

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
end
