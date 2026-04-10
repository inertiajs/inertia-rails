# frozen_string_literal: true

RSpec.describe InertiaRails::PropCacheable do
  let(:controller) do
    controller = ApplicationController.new
    request = double('Request')
    allow(controller).to receive(:request).and_return(request)
    allow(request).to receive(:headers).and_return({})
    controller
  end

  let(:cache_store) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(InertiaRails).to receive(:cache_store).and_return(cache_store)
  end

  # Test via DeferProp which prepends PropCacheable
  let(:prop_class) { InertiaRails::DeferProp }

  describe '#cached?' do
    it 'defaults to false' do
      prop = prop_class.new { 'value' }
      expect(prop.cached?).to be false
    end

    it 'returns true when cache is set with a string key' do
      prop = prop_class.new(cache: 'my_key') { 'value' }
      expect(prop.cached?).to be true
    end

    it 'returns true when cache is set with a hash key' do
      prop = prop_class.new(cache: { key: 'my_key', expires_in: 5 }) { 'value' }
      expect(prop.cached?).to be true
    end

    it 'raises ArgumentError when cache is a hash without :key' do
      expect { prop_class.new(cache: { expires_in: 5 }) { 'value' } }
        .to raise_error(ArgumentError, /requires a :key/)
    end
  end

  describe '#call' do
    context 'without cache' do
      it 'evaluates the block normally' do
        prop = prop_class.new { 'computed' }
        expect(prop.call(controller)).to eq('computed')
      end
    end

    context 'with cache: string key' do
      it 'evaluates block on cache miss, caches, and returns RawJson' do
        call_count = 0
        prop = prop_class.new(cache: 'test_key') do
          call_count += 1
          { items: [1, 2, 3] }
        end

        result = prop.call(controller)
        expect(result).to be_a(InertiaRails::RawJson)
        expect(result.to_json).to eq({ items: [1, 2, 3] }.to_json)
        expect(call_count).to eq(1)
        expect(cache_store.read('inertia_rails/test_key')).to eq({ items: [1, 2, 3] }.to_json)
      end

      it 'returns RawJson on cache hit without evaluating block' do
        cache_store.write('inertia_rails/test_key', '{"items":[1,2,3]}')

        call_count = 0
        prop = prop_class.new(cache: 'test_key') do
          call_count += 1
          'should not run'
        end

        result = prop.call(controller)
        expect(result).to be_a(InertiaRails::RawJson)
        expect(result.to_json).to eq('{"items":[1,2,3]}')
        expect(call_count).to eq(0)
      end
    end

    context 'with cache: array key' do
      it 'derives cache key from array' do
        prop = prop_class.new(cache: %w[stats user_1]) { { count: 42 } }
        prop.call(controller)

        expect(cache_store.read('inertia_rails/stats/user_1')).to eq({ count: 42 }.to_json)
      end
    end

    context 'with cache: hash (extended format)' do
      it 'extracts key and passes options to cache store' do
        prop = prop_class.new(cache: { key: 'test_key', expires_in: 1.second }) { 'value' }
        prop.call(controller)

        expect(cache_store.read('inertia_rails/test_key')).to eq('"value"')

        travel 2.seconds
        expect(cache_store.read('inertia_rails/test_key')).to be_nil
      end
    end

    context 'with cache: AR-like object' do
      it 'derives key from cache_key_with_version' do
        ar_object = double('ARObject')
        allow(ar_object).to receive(:cache_key_with_version).and_return('users/1-20260410')

        prop = prop_class.new(cache: ar_object) { { name: 'Bob' } }
        prop.call(controller)

        expect(cache_store.read('inertia_rails/users/1-20260410')).to eq({ name: 'Bob' }.to_json)
      end
    end

    context 'cache does not interfere with other prop options' do
      it 'preserves group option on DeferProp' do
        prop = prop_class.new(cache: 'key', group: 'sidebar') { 'value' }
        expect(prop.group).to eq('sidebar')
        expect(prop.cached?).to be true
      end

      it 'preserves once option on DeferProp' do
        prop = prop_class.new(cache: 'key', once: true) { 'value' }
        expect(prop.once?).to be true
        expect(prop.cached?).to be true
      end
    end
  end
end
