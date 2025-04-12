# frozen_string_literal: true

RSpec.describe InertiaRails::MergeProp do
  it_behaves_like 'base prop'

  describe '#merge?' do
    subject(:merge?) { prop.merge? }

    let(:prop) { described_class.new { 'block' } }

    it { is_expected.to be true }
  end

  describe '#deep_merge?' do
    subject(:deep_merge?) { prop.deep_merge? }

    let(:prop) { described_class.new { 'block' } }

    it { is_expected.to be false }

    context 'when deep_merge is true' do
      let(:prop) { described_class.new(deep_merge: true) { 'block' } }

      it { is_expected.to be true }
    end
  end
end
