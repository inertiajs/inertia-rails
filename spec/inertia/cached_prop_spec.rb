# frozen_string_literal: true

RSpec.describe InertiaRails::CachedProp do
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

  describe 'InertiaRails.cache(key) { block }' do
    it 'caches the block result and returns RawJson' do
      call_count = 0
      prop = InertiaRails.cache('stats') do
        call_count += 1
        { count: 42 }
      end

      result = prop.call(controller)
      expect(result).to be_a(InertiaRails::RawJson)
      expect(result.to_json).to eq({ count: 42 }.to_json)
      expect(call_count).to eq(1)

      result2 = prop.call(controller)
      expect(result2).to be_a(InertiaRails::RawJson)
      expect(result2.to_json).to eq({ count: 42 }.to_json)
      expect(call_count).to eq(1)
    end
  end

  describe 'InertiaRails.cache(key: ..., expires_in: ...) { block }' do
    it 'passes options to cache store' do
      prop = InertiaRails.cache(key: 'stats', expires_in: 0.1) { 'value' }
      prop.call(controller)

      expect(cache_store.read('inertia_rails/stats')).to eq('"value"')

      travel 1.second
      expect(cache_store.read('inertia_rails/stats')).to be_nil
    end
  end

  describe 'InertiaRails.cache(key, expires_in: ...) { block }' do
    it 'accepts positional key with keyword options' do
      prop = InertiaRails.cache('stats', expires_in: 0.1) { 'value' }
      prop.call(controller)

      expect(cache_store.read('inertia_rails/stats')).to eq('"value"')
    end
  end

  describe 'InertiaRails.cache(ar_object) { block }' do
    it 'derives key from cache_key_with_version' do
      ar_object = double('ARObject')
      allow(ar_object).to receive(:cache_key_with_version).and_return('posts/1-20260410')

      prop = InertiaRails.cache(ar_object) { { title: 'Hello' } }
      prop.call(controller)

      expect(cache_store.read('inertia_rails/posts/1-20260410')).to eq({ title: 'Hello' }.to_json)
    end
  end

  describe 'InertiaRails.cache({key: ..., expires_in: ...}) { block }' do
    it 'accepts a positional hash with key and options' do
      prop = InertiaRails.cache({ key: 'stats', expires_in: 0.1 }) { 'value' }
      prop.call(controller)

      expect(cache_store.read('inertia_rails/stats')).to eq('"value"')

      travel 1.second
      expect(cache_store.read('inertia_rails/stats')).to be_nil
    end
  end

  describe 'InertiaRails.cache(ar_object, expires_in: ...) { block }' do
    it 'accepts AR object with keyword options' do
      ar_object = double('ARObject')
      allow(ar_object).to receive(:cache_key_with_version).and_return('posts/1-20260410')

      prop = InertiaRails.cache(ar_object, expires_in: 0.1) { 'value' }
      prop.call(controller)

      expect(cache_store.read('inertia_rails/posts/1-20260410')).to eq('"value"')

      travel 1.second
      expect(cache_store.read('inertia_rails/posts/1-20260410')).to be_nil
    end
  end

  describe 'InertiaRails.cache { block } with no key' do
    it 'raises ArgumentError' do
      expect { InertiaRails.cache { 'value' } }.to raise_error(ArgumentError, /cache key is required/)
    end
  end
end
