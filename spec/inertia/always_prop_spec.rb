RSpec.describe InertiaRails::AlwaysProp do
  describe '#call' do
    subject(:call) { prop.call }
    let(:prop) { described_class.new('value') }

    it { is_expected.to eq('value') }

    context 'with a callable value' do
      let(:prop) { described_class.new(-> { 'callable' }) }

      it { is_expected.to eq('callable') }
    end

    context 'with a block' do
      let(:prop) { described_class.new { 'block' } }

      it { is_expected.to eq('block') }
    end
  end
end
