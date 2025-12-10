# frozen_string_literal: true

RSpec.describe InertiaRails::OnceProp do
  it_behaves_like 'base prop'

  describe '#once?' do
    subject { prop.once? }

    let(:prop) { described_class.new { 'value' } }

    it { is_expected.to be true }
  end

  describe '#once_key' do
    subject { prop.once_key }

    context 'without custom key' do
      let(:prop) { described_class.new { 'value' } }

      it { is_expected.to be_nil }
    end

    context 'with custom key via constructor' do
      let(:prop) { described_class.new(key: 'custom_key') { 'value' } }

      it { is_expected.to eq('custom_key') }
    end
  end

  describe '#once_expires_in' do
    subject { prop.once_expires_in }

    context 'without expires_in' do
      let(:prop) { described_class.new { 'value' } }

      it { is_expected.to be_nil }
    end

    context 'with expires_in via constructor' do
      let(:prop) { described_class.new(expires_in: 3600) { 'value' } }

      it { is_expected.to eq(3600) }
    end
  end

  describe '#expires_at' do
    subject { prop.expires_at }

    let(:freeze_time) { Time.current }

    before do
      allow(Time).to receive(:current).and_return(freeze_time)
    end

    context 'without expires_in' do
      let(:prop) { described_class.new { 'value' } }

      it { is_expected.to be_nil }
    end

    context 'with Numeric (seconds)' do
      let(:prop) { described_class.new(expires_in: 3600) { 'value' } }

      it 'returns expiration timestamp in milliseconds' do
        expected = ((freeze_time.to_f + 3600) * 1000).to_i
        expect(prop.expires_at).to eq(expected)
      end
    end

    context 'with ActiveSupport::Duration' do
      let(:prop) { described_class.new(expires_in: 1.hour) { 'value' } }

      it 'returns expiration timestamp in milliseconds' do
        expected = ((freeze_time + 1.hour).to_f * 1000).to_i
        expect(prop.expires_at).to eq(expected)
      end
    end
  end

  describe '#once? is independent of fresh' do
    subject { prop.once? }

    context 'when fresh is false (default)' do
      let(:prop) { described_class.new { 'value' } }

      it { is_expected.to be true }
    end

    context 'when fresh is true' do
      let(:prop) { described_class.new(fresh: true) { 'value' } }

      it { is_expected.to be true }
    end
  end

  describe '#fresh?' do
    subject { prop.fresh? }

    context 'when fresh is false (default)' do
      let(:prop) { described_class.new { 'value' } }

      it { is_expected.to be false }
    end

    context 'when fresh is true' do
      let(:prop) { described_class.new(fresh: true) { 'value' } }

      it { is_expected.to be true }
    end
  end
end
