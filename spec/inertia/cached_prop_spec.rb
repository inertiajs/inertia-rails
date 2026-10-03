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

  describe 'InertiaRails.cache(key) { serializer }' do
    it 'caches what the serializer returns, not its instance variables' do
      user = Object.new
      user.instance_variable_set(:@secret, 'hunter2')
      def user.to_inertia = { name: 'Jonathan' }

      InertiaRails.cache('user') do
        { user: user, list: [user], options: ActiveSupport::HashWithIndifferentAccess.new(user: user) }
      end.call(controller)

      expect(cache_store.read('inertia_rails/@2/user')).to eq(
        { user: { name: 'Jonathan' }, list: [{ name: 'Jonathan' }], options: { user: { name: 'Jonathan' } } }.to_json
      )
    end

    it 'evaluates closures and prop types the serializer returns, since the value is replayed to every visit' do
      course = Object.new
      def course.to_inertia = { title: -> { 'Ruby' }, students: InertiaRails.optional { 12 } }

      result = InertiaRails.cache('course') { course }.call(controller)

      expect(result.to_json).to eq({ title: 'Ruby', students: 12 }.to_json)
    end

    it 'ignores entries cached before serializers were resolved' do
      cache_store.write('inertia_rails/user', '{"secret":"hunter2"}')

      result = InertiaRails.cache('user') { { name: 'Jonathan' } }.call(controller)

      expect(result.to_json).to eq({ name: 'Jonathan' }.to_json)
    end
  end

  describe 'InertiaRails.cache(key, expires_in: ...) { block }' do
    it 'accepts positional key with keyword options' do
      prop = InertiaRails.cache('stats', expires_in: 1.second) { 'value' }
      prop.call(controller)

      expect(cache_store.read('inertia_rails/@2/stats')).to eq('"value"')
    end
  end

  describe 'InertiaRails.cache(ar_object) { block }' do
    it 'derives key from cache_key_with_version' do
      ar_object = double('ARObject')
      allow(ar_object).to receive(:cache_key_with_version).and_return('posts/1-20260410')

      prop = InertiaRails.cache(ar_object) { { title: 'Hello' } }
      prop.call(controller)

      expect(cache_store.read('inertia_rails/@2/posts/1-20260410')).to eq({ title: 'Hello' }.to_json)
    end
  end

  describe 'InertiaRails.cache(ar_object, expires_in: ...) { block }' do
    it 'accepts AR object with keyword options' do
      ar_object = double('ARObject')
      allow(ar_object).to receive(:cache_key_with_version).and_return('posts/1-20260410')

      prop = InertiaRails.cache(ar_object, expires_in: 1.second) { 'value' }
      prop.call(controller)

      expect(cache_store.read('inertia_rails/@2/posts/1-20260410')).to eq('"value"')

      travel 2.seconds
      expect(cache_store.read('inertia_rails/@2/posts/1-20260410')).to be_nil
    end
  end
end
