# frozen_string_literal: true

require 'rails_helper'
require 'action_cable'
require 'active_job'

RSpec.describe 'Live prop broadcasts' do
  let(:server) { instance_double(ActionCable::Server::Base, broadcast: nil) }
  let(:record) { double('Exhibit', to_gid_param: 'gid://dummy/Exhibit/1') }

  before { allow(ActionCable).to receive(:server).and_return(server) }

  def envelope(**fields)
    { '__inertia' => { 'event' => 'refresh', **fields.transform_keys(&:to_s) } }
  end

  def with_request(headers)
    InertiaRails::Current.request = ActionDispatch::TestRequest.create(
      headers.transform_keys { |name| "HTTP_#{name.upcase.tr('-', '_')}" }
    )
    yield
  ensure
    InertiaRails::Current.reset
  end

  describe 'InertiaRails.broadcast' do
    it 'tells the stream it changed, with no data' do
      InertiaRails.broadcast(record, :guestbook)

      expect(server).to have_received(:broadcast).with('inertia:gid://dummy/Exhibit/1:guestbook', envelope)
    end

    it 'broadcasts to each stream from `streams:`' do
      InertiaRails.broadcast(streams: [record, :feed])

      expect(server).to have_received(:broadcast).with('inertia:gid://dummy/Exhibit/1', envelope)
      expect(server).to have_received(:broadcast).with('inertia:feed', envelope)
    end

    it 'pushes resolved values, keeping keys literal' do
      serializer = Object.new
      def serializer.to_inertia = { id: 1, title: 'Mona Lisa' }

      InertiaRails.broadcast(:feed, props: { exhibit: serializer, 'stats.revenue' => 42, related: [serializer] })

      expect(server).to have_received(:broadcast).with(
        'inertia:feed',
        envelope(props: {
                   exhibit: { id: 1, title: 'Mona Lisa' },
                   'stats.revenue' => 42,
                   related: [{ id: 1, title: 'Mona Lisa' }],
                 })
      )
    end

    it 'runs pushed values through the prop transformer, like a page' do
      allow(InertiaRails.configuration).to receive(:prop_transformer) do |props:|
        props.except(:secret).deep_transform_keys { |key| key.to_s.camelize(:lower) }
      end

      InertiaRails.broadcast(:feed, props: { order: { updated_at: '12:00' }, catalog_size: 3, secret: 's3cr3t' })
      InertiaRails.broadcast(:refresh)

      # catalogSize no longer matches the liveProps key catalog_size, so the client reloads it instead.
      expect(server).to have_received(:broadcast).with(
        'inertia:feed', envelope(props: { 'order' => { 'updatedAt' => '12:00' }, 'catalogSize' => 3 })
      )
      expect(server).to have_received(:broadcast).with('inertia:refresh', envelope)
    end

    it 'wraps big integers in pushed values when preserve_big_integers is on' do
      InertiaRails.broadcast(:plain, props: { id: 2**60 })
      allow(InertiaRails.configuration).to receive(:preserve_big_integers).and_return(true)
      InertiaRails.broadcast(:feed, props: { id: 2**60, count: 3 })

      expect(server).to have_received(:broadcast).with('inertia:plain', envelope(props: { id: 2**60 }))
      expect(server).to have_received(:broadcast).with(
        'inertia:feed', envelope(props: { id: { '$bigint' => (2**60).to_s }, count: 3 })
      )
    end

    it 'refuses prop types and non-hash props' do
      expect { InertiaRails.broadcast(:feed, props: { feed: InertiaRails.defer { 1 } }) }
        .to raise_error(ArgumentError, /not prop types/)
      expect { InertiaRails.broadcast(:feed, props: [1]) }.to raise_error(ArgumentError, /hash/)
    end

    it 'skips the sender with `to_others: true`' do
      with_request('X-Socket-Id' => 'tab-123.4') { InertiaRails.broadcast(:feed, to_others: true) }

      expect(server).to have_received(:broadcast).with('inertia:feed', envelope(socketId: 'tab-123.4'))
    end

    it 'reaches everyone by default, even when the request has a socket id' do
      with_request('X-Socket-Id' => 'tab-123') { InertiaRails.broadcast(:feed) }

      expect(server).to have_received(:broadcast).with('inertia:feed', envelope)
    end

    it 'reaches everyone when there is no request' do
      InertiaRails.broadcast(:feed, to_others: true)

      expect(server).to have_received(:broadcast).with('inertia:feed', envelope)
    end
  end

  describe 'InertiaRails.broadcast_later' do
    around do |example|
      adapter = ActiveJob::Base.queue_adapter
      logger = ActiveJob::Base.logger
      ActiveJob::Base.queue_adapter = :test
      ActiveJob::Base.logger = Logger.new(nil)
      example.run
    ensure
      ActiveJob::Base.queue_adapter = adapter
      ActiveJob::Base.logger = logger
    end

    let(:enqueued) { ActiveJob::Base.queue_adapter.enqueued_jobs }

    it 'enqueues stream names, not records, so destroyed records still broadcast' do
      with_request('X-Socket-Id' => 'tab-1') do
        InertiaRails.broadcast_later(record, :guestbook, to_others: true)
        InertiaRails.broadcast_later(:feed)
      end

      expect(enqueued.map { |job| job[:job] }.uniq).to eq([InertiaRails::LiveBroadcastJob])
      expect(enqueued.map { |job| job[:args] })
        .to eq([[['inertia:gid://dummy/Exhibit/1:guestbook'], 'tab-1'], [['inertia:feed'], nil]])
    end

    it 'publishes from the job' do
      InertiaRails::LiveBroadcastJob.perform_now(%w[inertia:a inertia:b], 'tab-1')

      expect(server).to have_received(:broadcast).with('inertia:a', envelope(socketId: 'tab-1'))
      expect(server).to have_received(:broadcast).with('inertia:b', envelope(socketId: 'tab-1'))
    end
  end

  describe 'model macros' do
    let(:model) do
      stub_const('Exhibit', Class.new do
        def self.callbacks = (@callbacks ||= Hash.new { |hash, key| hash[key] = [] })
        def self.model_name = ActiveModel::Name.new(self)

        %i[after_create_commit after_update_commit after_destroy_commit after_commit].each do |name|
          define_singleton_method(name) { |callback| callbacks[name] << callback }
        end

        include InertiaRails::LiveBroadcastable

        def exhibit = :parent
      end)
    end
    let(:instance) { model.new }

    before { allow(InertiaRails::LiveBroadcast).to receive(:broadcast_later) }

    def run(callback)
      model.callbacks.fetch(callback).each { |lambda| instance.instance_exec(&lambda) }
    end

    it 'inertia_broadcasts: create refreshes the collection, update and destroy the record' do
      model.inertia_broadcasts

      run(:after_create_commit)
      expect(InertiaRails::LiveBroadcast).to have_received(:broadcast_later).with('exhibits')

      run(:after_update_commit)
      run(:after_destroy_commit)
      expect(InertiaRails::LiveBroadcast).to have_received(:broadcast_later).with(instance).twice
    end

    it 'inertia_broadcasts_to: a method name or a lambda' do
      model.inertia_broadcasts_to :exhibit
      model.inertia_broadcasts_to ->(record) { [record.exhibit, :guestbook] }

      run(:after_commit)

      expect(InertiaRails::LiveBroadcast).to have_received(:broadcast_later).with(:parent)
      expect(InertiaRails::LiveBroadcast).to have_received(:broadcast_later).with(%i[parent guestbook])
    end

    it 'suppressing_inertia_broadcasts skips them inside the block and restores after an error' do
      model.inertia_broadcasts

      expect do
        model.suppressing_inertia_broadcasts do
          run(:after_update_commit)
          raise 'boom'
        end
      end.to raise_error('boom')
      expect(InertiaRails::LiveBroadcast).not_to have_received(:broadcast_later)

      run(:after_update_commit)
      expect(InertiaRails::LiveBroadcast).to have_received(:broadcast_later).once
    end

    it 'suppressing_inertia_broadcasts nests, and stays on its thread' do
      model.inertia_broadcasts

      model.suppressing_inertia_broadcasts do
        model.suppressing_inertia_broadcasts { nil }
        run(:after_update_commit)
        Thread.new { run(:after_update_commit) }.join
      end

      expect(InertiaRails::LiveBroadcast).to have_received(:broadcast_later).once
    end
  end
end
