# frozen_string_literal: true

RSpec.describe InertiaRails::PropOnceable do
  describe 'via DeferProp' do
    let(:prop_class) { InertiaRails::DeferProp }

    describe '#once?' do
      it 'defaults to false' do
        prop = prop_class.new { 'value' }
        expect(prop.once?).to be false
      end

      it 'can be set to true' do
        prop = prop_class.new(once: true) { 'value' }
        expect(prop.once?).to be true
      end

      context 'once? is independent of fresh' do
        it 'returns true when once is true regardless of fresh' do
          prop = prop_class.new(once: true, fresh: true) { 'value' }
          expect(prop.once?).to be true
        end

        it 'returns false when once is false regardless of fresh' do
          prop = prop_class.new(once: false, fresh: true) { 'value' }
          expect(prop.once?).to be false
        end
      end
    end

    describe '#fresh?' do
      it 'defaults to false' do
        prop = prop_class.new(once: true) { 'value' }
        expect(prop.fresh?).to be false
      end

      it 'can be set to true' do
        prop = prop_class.new(once: true, fresh: true) { 'value' }
        expect(prop.fresh?).to be true
      end
    end

    describe '#once_key' do
      it 'defaults to nil' do
        prop = prop_class.new { 'value' }
        expect(prop.once_key).to be_nil
      end

      it 'can be set via constructor' do
        prop = prop_class.new(once: true, key: 'custom') { 'value' }
        expect(prop.once_key).to eq('custom')
      end
    end

    describe '#once_expires_in' do
      it 'defaults to nil' do
        prop = prop_class.new { 'value' }
        expect(prop.once_expires_in).to be_nil
      end

      it 'can be set via constructor' do
        prop = prop_class.new(once: true, expires_in: 3600) { 'value' }
        expect(prop.once_expires_in).to eq(3600)
      end
    end

    describe '#expires_at' do
      let(:freeze_time) { Time.current }

      before do
        allow(Time).to receive(:current).and_return(freeze_time)
      end

      it 'returns nil without expires_in' do
        prop = prop_class.new(once: true) { 'value' }
        expect(prop.expires_at).to be_nil
      end

      it 'returns expiration timestamp in milliseconds with expires_in' do
        prop = prop_class.new(once: true, expires_in: 3600) { 'value' }
        expected = ((freeze_time.to_f + 3600) * 1000).to_i
        expect(prop.expires_at).to eq(expected)
      end
    end

    it 'preserves existing DeferProp functionality' do
      prop = prop_class.new(group: 'custom', once: true) { 'value' }
      expect(prop.group).to eq('custom')
      expect(prop.once?).to be true
    end
  end

  describe 'via OptionalProp' do
    let(:prop_class) { InertiaRails::OptionalProp }

    it 'supports once functionality' do
      prop = prop_class.new(once: true, key: 'opt_key', expires_in: 1800) { 'value' }
      expect(prop.once?).to be true
      expect(prop.once_key).to eq('opt_key')
      expect(prop.once_expires_in).to eq(1800)
    end

    it 'defaults to not once' do
      prop = prop_class.new { 'value' }
      expect(prop.once?).to be false
    end
  end

  describe 'via MergeProp' do
    let(:prop_class) { InertiaRails::MergeProp }

    it 'supports once functionality' do
      prop = prop_class.new(once: true, key: 'merge_key', expires_in: 7200) { 'value' }
      expect(prop.once?).to be true
      expect(prop.once_key).to eq('merge_key')
      expect(prop.once_expires_in).to eq(7200)
    end

    it 'preserves merge functionality' do
      prop = prop_class.new(once: true) { 'value' }
      expect(prop.merge?).to be true
      expect(prop.once?).to be true
    end
  end
end
