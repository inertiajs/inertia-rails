RSpec.describe InertiaRails::DeferProp do
  describe '#call' do
    subject(:call) { prop.call }
    let(:prop) { described_class.new('value') }

    it { is_expected.to eq('value') }

    it 'returns the default group' do
      expect(prop.group).to eq('default')
    end

    context "with group" do
      let(:prop) { described_class.new('value', group: 'custom') }

      it 'returns the group' do
        expect(prop.group).to eq('custom')
      end
    end

    context 'with a callable value' do
      let(:prop) { described_class.new(-> { 'callable' }) }

      it { is_expected.to eq('callable') }

      context "with group" do
        let(:prop) { described_class.new(-> { 'callable' }, group: 'custom') }

        it 'returns the group' do
          expect(prop.group).to eq('custom')
        end
      end
    end

    context 'with a block' do
      let(:prop) { described_class.new { 'block' } }

      it { is_expected.to eq('block') }

      context "with group" do
        let(:prop) { described_class.new(group: 'custom') { 'block' } }

        it 'returns the group' do
          expect(prop.group).to eq('custom')
        end
      end
    end

    it 'returns the merge flag' do
      expect(prop.merge?).to be_falsey
      prop.merge

      expect(prop.merge?).to be(true)
    end
  end
end
