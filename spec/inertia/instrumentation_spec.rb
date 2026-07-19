# frozen_string_literal: true

RSpec.describe 'inertia instrumentation', type: :request do
  def collect_events(name)
    events = []
    subscription = ActiveSupport::Notifications.subscribe(name) do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end
    yield
    events
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  describe 'render.inertia_rails' do
    it 'instruments full page loads' do
      events = collect_events('render.inertia_rails') { get props_path }

      expect(events.size).to eq(1)
      expect(events.first.payload).to include(component: 'TestComponent', partial: false, ssr: false)
    end

    it 'instruments inertia requests' do
      events = collect_events('render.inertia_rails') do
        get props_path, headers: { 'X-Inertia' => true }
      end

      expect(events.size).to eq(1)
      expect(events.first.payload).to include(component: 'TestComponent', partial: false, ssr: false)
    end

    it 'marks partial reloads' do
      events = collect_events('render.inertia_rails') do
        get props_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Partial-Component' => 'TestComponent',
          'X-Inertia-Partial-Data' => 'sport',
        }
      end

      expect(events.first.payload).to include(component: 'TestComponent', partial: true)
    end
  end

  describe 'resolve_props.inertia_rails' do
    it 'instruments prop resolution once per render' do
      events = collect_events('resolve_props.inertia_rails') { get props_path }

      expect(events.size).to eq(1)
      expect(events.first.payload).to include(component: 'TestComponent', partial: false)
    end
  end

  describe 'ssr.inertia_rails' do
    with_inertia_config ssr_enabled: true, ssr_url: 'http://localhost:13714', version: '1.0'

    context 'with a successful ssr response' do
      before do
        http_response = instance_double(
          Net::HTTPOK,
          body: { body: '<div>SSR</div>', head: ['<title>SSR</title>'] }.to_json,
          code: '200'
        )
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        http_double = instance_double(Net::HTTP)
        allow(http_double).to receive(:post).and_return(http_response)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)
      end

      it 'instruments the ssr http call' do
        events = collect_events('ssr.inertia_rails') { get props_path }

        expect(events.size).to eq(1)
        expect(events.first.payload).to include(
          url: 'http://localhost:13714/render',
          component: 'TestComponent'
        )
      end

      it 'marks the render event as ssr' do
        events = collect_events('render.inertia_rails') { get props_path }

        expect(events.first.payload).to include(ssr: true)
      end

      context 'with ssr_cache enabled' do
        with_inertia_config ssr_cache: true

        let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

        before { allow(Rails).to receive(:cache).and_return(memory_store) }

        it 'does not instrument cache hits' do
          events = collect_events('ssr.inertia_rails') do
            get props_path
            get props_path
          end

          expect(events.size).to eq(1)
        end
      end
    end

    context 'with a failing ssr call' do
      before { allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED) }

      it 'records the exception on the event and falls back to CSR' do
        ssr_events = nil
        render_events = collect_events('render.inertia_rails') do
          ssr_events = collect_events('ssr.inertia_rails') { get props_path }
        end

        expect(ssr_events.size).to eq(1)
        expect(ssr_events.first.payload[:exception_object]).to be_a(Errno::ECONNREFUSED)
        expect(render_events.first.payload).to include(ssr: false)
      end
    end
  end
end
