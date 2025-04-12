# frozen_string_literal: true

RSpec.describe InertiaRails::DeferProp do
  it_behaves_like 'base prop'

  describe '#merge?' do
    subject(:merge?) { prop.merge? }

    let(:prop) { described_class.new { 'block' } }

    it { is_expected.to be_falsy }

    context 'when merge is set' do
      let(:prop) { described_class.new(merge: true) { 'block' } }

      it { is_expected.to be true }
    end

    context 'when deep_merge is set' do
      let(:prop) { described_class.new(deep_merge: true) { 'block' } }

      it { is_expected.to be true }
    end

    context 'when both merge and deep_merge are set' do
      let(:prop) { described_class.new(merge: true, deep_merge: true) { 'block' } }

      it 'raises an ArgumentError' do
        expect { merge? }.to raise_error(ArgumentError, 'Cannot set both `deep_merge` and `merge` to true')
      end
    end
  end

  describe '#deep_merge?' do
    subject(:deep_merge?) { prop.deep_merge? }

    let(:prop) { described_class.new { 'block' } }

    it { is_expected.to be_falsy }

    context 'when deep is true' do
      let(:prop) { described_class.new(deep_merge: true) { 'block' } }

      it { is_expected.to be true }
    end
  end

  describe '#group' do
    subject(:group) { prop.group }

    let(:prop) { described_class.new { 'block' } }

    it { is_expected.to eq('default') }

    context 'when group is set' do
      let(:prop) { described_class.new(group: 'custom') { 'block' } }

      it { is_expected.to eq('custom') }
    end
  end
end
