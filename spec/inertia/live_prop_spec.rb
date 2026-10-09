# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Live props' do
  let(:evaluator) { InertiaRails::PropEvaluator.new(Object.new) }

  def resolve(props, visit: {})
    resolved_props, metadata = InertiaRails::PropsResolver.new(props, evaluator: evaluator, visit: visit).resolve
    { props: resolved_props }.merge(metadata)
  end

  def resolve_partial(props, *only, **visit)
    resolve(props, visit: { component: true, only: only.map(&:to_s), **visit })
  end

  def listener(name)
    { channel: { name: InertiaRails::LiveStream.signed(name), type: 'public' }, events: ['refresh'] }
  end

  describe 'declaring' do
    it 'accepts `live:` on defer, optional, once, and always' do
      [
        InertiaRails.defer(live: :feed) { 1 },
        InertiaRails.optional(live: :feed) { 1 },
        InertiaRails.once(live: :feed) { 1 },
        InertiaRails.always(live: :feed) { 1 }
      ].each { |prop| expect(prop).to be_live }
    end

    it 'accepts `live:` on a cached prop, keeping it out of the cache options' do
      store = ActiveSupport::Cache::MemoryStore.new
      allow(InertiaRails).to receive(:cache_store).and_return(store)
      allow(store).to receive(:fetch).and_call_original

      page = resolve({ stats: InertiaRails.cache('stats', live: :stats, throttle: 500) { 1 } })

      expect(page[:liveProps]['stats']).to include(throttle: 500)
      expect(store).to have_received(:fetch).with('inertia_rails/@2/stats')
    end

    it 'takes a throttle in milliseconds or as a duration' do
      expect(InertiaRails.live(:feed, throttle: 4000) { 1 }.live_metadata[:throttle]).to eq(4000)
      expect(InertiaRails.defer(live: :feed, throttle: 1.5.seconds) { 1 }.live_metadata[:throttle]).to eq(1500)
    end

    it 'refuses a throttle without `live:`' do
      expect { InertiaRails.defer(throttle: 4000) { 1 } }.to raise_error(ArgumentError, /needs `live:`/)
    end

    it 'refuses live updates on props that merge' do
      expect { InertiaRails.merge(live: :feed) { [] } }.to raise_error(ArgumentError, /merge props/)
      expect { InertiaRails.defer(merge: true, live: :feed) { [] } }.to raise_error(ArgumentError, /merge props/)
      expect { InertiaRails.scroll(live: :feed) { [] } }.to raise_error(ArgumentError, /merge props/)
    end
  end

  describe 'liveProps on a full load' do
    it 'lists each live prop with its listeners and throttle' do
      page = resolve({
                       guestbook: InertiaRails.live(:exhibit, :guestbook) { [] },
                       visitors: InertiaRails.live(:exhibit, throttle: 4000) { 3 },
                       title: 'Mona Lisa',
                     })

      expect(page[:props]).to eq(guestbook: [], visitors: 3, title: 'Mona Lisa')
      expect(page[:liveProps]).to eq(
        'guestbook' => { listeners: [listener('inertia:exhibit:guestbook')] },
        'visitors' => { listeners: [listener('inertia:exhibit')], throttle: 4000 }
      )
    end

    it 'lists live props the response leaves out, so the page subscribes to them' do
      page = resolve({
                       related: InertiaRails.defer(live: :exhibit) { raise 'not evaluated' },
                       notes: InertiaRails.optional(live: :exhibit) { raise 'not evaluated' },
                       plans: InertiaRails.once(live: :plans) { raise 'not evaluated' },
                     }, visit: { except_once: ['plans'] })

      expect(page[:props]).to be_empty
      expect(page[:liveProps].keys).to eq(%w[related notes plans])
    end

    it 'gives one listener per stream from `streams:`' do
      page = resolve({ alerts: InertiaRails.live(streams: [:order, %i[user alerts]]) { [] } })

      expect(page[:liveProps]['alerts'][:listeners])
        .to eq([listener('inertia:order'), listener('inertia:user:alerts')])
    end

    it 'keys nested live props by dot path' do
      page = resolve({
                       order: { total: InertiaRails.live(:order) { 120 } },
                       'stats.revenue' => InertiaRails.live(:stats) { 5 },
                     })

      expect(page[:props]).to eq(order: { total: 120 }, stats: { revenue: 5 })
      expect(page[:liveProps].keys).to eq(%w[order.total stats.revenue])
    end

    it 'lists a live prop returned from a closure' do
      page = resolve({ feed: -> { InertiaRails.live(:feed) { [1] } } })

      expect(page[:props]).to eq(feed: [1])
      expect(page[:liveProps].keys).to eq(['feed'])
    end

    it 'omits the key when nothing is live' do
      expect(resolve({ title: 'Mona Lisa' })).not_to have_key(:liveProps)
    end
  end

  describe 'liveProps on a partial reload' do
    let(:props) do
      {
        order: InertiaRails.live(:order) { 'order' },
        stats: InertiaRails.live(:order) { 'stats' },
        flash: InertiaRails.always(live: :flash) { 'flash' },
      }
    end

    it 'lists only the props the reload asks for; the client keeps the rest' do
      page = resolve_partial(props, 'order')

      expect(page[:props]).to eq(order: 'order', flash: 'flash')
      expect(page[:liveProps].keys).to eq(%w[order])
    end
  end
end
