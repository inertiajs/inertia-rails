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

  describe 'append/prepend behavior' do
    it 'appends by default' do
      prop = described_class.new { [] }

      expect(prop.appends_at_root?).to be true
      expect(prop.prepends_at_root?).to be false
      expect(prop.appends_at_paths).to eq([])
      expect(prop.prepends_at_paths).to eq([])
      expect(prop.match_on).to be_nil
    end

    it 'can be configured to prepend' do
      prop = described_class.new(prepend: true) { [] }

      expect(prop.appends_at_root?).to be false
      expect(prop.prepends_at_root?).to be true
      expect(prop.appends_at_paths).to eq([])
      expect(prop.prepends_at_paths).to eq([])
      expect(prop.match_on).to be_nil
    end

    it 'supports appending with nested merge paths' do
      prop = described_class.new(append: 'data') { [] }

      expect(prop.appends_at_root?).to be false
      expect(prop.prepends_at_root?).to be false
      expect(prop.appends_at_paths).to eq(['data'])
      expect(prop.prepends_at_paths).to eq([])
      expect(prop.match_on).to be_nil
    end

    it 'supports appending with nested merge paths and match_on' do
      prop = described_class.new(append: { data: 'id' }) { [] }

      expect(prop.appends_at_root?).to be false
      expect(prop.prepends_at_root?).to be false
      expect(prop.appends_at_paths).to eq(['data'])
      expect(prop.prepends_at_paths).to eq([])
      expect(prop.match_on).to eq(['data.id'])
    end

    it 'supports prepending with nested merge paths' do
      prop = described_class.new(prepend: 'data') { [] }

      expect(prop.appends_at_root?).to be false
      expect(prop.prepends_at_root?).to be false
      expect(prop.appends_at_paths).to eq([])
      expect(prop.prepends_at_paths).to eq(['data'])
      expect(prop.match_on).to be_nil
    end

    it 'supports prepending with nested merge paths and match_on' do
      prop = described_class.new(prepend: { data: 'id' }) { [] }

      expect(prop.appends_at_root?).to be false
      expect(prop.prepends_at_root?).to be false
      expect(prop.appends_at_paths).to eq([])
      expect(prop.prepends_at_paths).to eq(['data'])
      expect(prop.match_on).to eq(['data.id'])
    end

    it 'supports append with nested merge paths as array' do
      prop = described_class.new(append: %w[data items]) { [] }

      expect(prop.appends_at_root?).to be false
      expect(prop.prepends_at_root?).to be false
      expect(prop.appends_at_paths).to eq(%w[data items])
      expect(prop.prepends_at_paths).to eq([])
      expect(prop.match_on).to be_nil
    end

    it 'supports prepend with nested merge paths as array' do
      prop = described_class.new(prepend: %w[data items]) { [] }

      expect(prop.appends_at_root?).to be false
      expect(prop.prepends_at_root?).to be false
      expect(prop.appends_at_paths).to eq([])
      expect(prop.prepends_at_paths).to eq(%w[data items])
      expect(prop.match_on).to be_nil
    end

    it 'supports complex mix of append and prepend with nested merge paths and match_on' do
      prop = described_class.new(
        append: {
          data: nil,
          users: 'id',
          posts: nil,
        },
        prepend: {
          categories: nil,
          companies: :id,
          comments: nil,
        },
        match_on: %w[comments.key]
      ) { [] }

      expect(prop.appends_at_root?).to be false
      expect(prop.prepends_at_root?).to be false
      expect(prop.appends_at_paths).to match_array(%w[data users posts])
      expect(prop.prepends_at_paths).to match_array(%w[categories companies comments])
      expect(prop.match_on).to match_array(%w[comments.key users.id companies.id])
    end
  end
end
