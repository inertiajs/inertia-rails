RSpec.describe InertiaRails::MergeProp do
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

    it 'returns the merge flag' do
      expect(prop.merge?).to eq(true)
    end
  end
end
