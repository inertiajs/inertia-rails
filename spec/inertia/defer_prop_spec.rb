RSpec.describe InertiaRails::DeferProp do
  let(:prop) { described_class.new('value') }

  it_behaves_like 'callable prop'

  describe '#group' do
    subject(:group) { prop.group }

    it 'returns the default group' do
      expect(group).to eq('default')
    end

    context "with a custom group" do
      let(:prop) { described_class.new('value', group: 'custom') }

      it 'returns the group' do
        expect(group).to eq('custom')
      end

      context 'with a callable value' do
        let(:prop) { described_class.new(-> { 'callable' }, group: 'custom') }

        it 'returns the group' do
          expect(group).to eq('custom')
        end
      end

      context 'with a block' do
        let(:prop) { described_class.new(group: 'custom') { 'block' } }

        it 'returns the group' do
          expect(prop.group).to eq('custom')
        end
      end
    end
  end

  describe '#merge' do
    it 'updates the merge value' do
      expect(prop.merge?).to be_falsey
      prop.merge

      expect(prop.merge?).to be(true)
    end
  end
end
