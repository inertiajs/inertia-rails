# frozen_string_literal: true

RSpec.describe 'Inertia DevTools recorder', type: :request do
  before { InertiaRails::DevTools.reset! }
  after { InertiaRails::DevTools.reset! }

  context 'when disabled' do
    with_inertia_config devtools_enabled: false

    it 'does not record or expose discovery artifacts' do
      get empty_test_path

      expect(response.headers[InertiaRails::DevTools::ID_HEADER]).to be_nil
      expect(response.body).not_to include('data-inertia-devtools-id')
      expect(InertiaRails::DevTools.store.all).to be_empty
    end

    it 'does not expose the entries endpoint' do
      get '/_inertia/devtools/entries'

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when enabled and authorized' do
    with_inertia_config(
      devtools_enabled: true,
      devtools_authorize: ->(_request) { true },
      devtools_max_entries: 500,
      devtools_entry_ttl: 3600
    )

    it 'emits a discovery header and injects the initial page discovery tag' do
      get empty_test_path

      id = response.headers[InertiaRails::DevTools::ID_HEADER]

      expect(id).to match(InertiaRails::DevTools::Middleware::ID_PATTERN)
      expect(response.headers[InertiaRails::DevTools::OUTGOING_PARENT_HEADER]).to eq(id)
      expect(response.body).to include(
        %(<script data-inertia-devtools-id type="application/json">#{id.to_json}</script>)
      )
    end

    it 'returns an extension-compatible entry for a known ID' do
      get props_path, headers: {
        'X-Inertia' => 'true',
        'X-Inertia-Devtools-Tab' => 'tab-123',
        'X-Inertia-Devtools-Visit' => 'visit-456',
        'X-Inertia-Devtools-Parent' => 'parent-789',
      }

      id = response.headers[InertiaRails::DevTools::ID_HEADER]
      expect(response.headers[InertiaRails::DevTools::OUTGOING_PARENT_HEADER]).to eq('parent-789')

      get "/_inertia/devtools/entries/#{id}"

      expect(response).to have_http_status(:ok)
      entry = response.parsed_body

      expect(entry.dig('__meta', 'id')).to eq(id)
      expect(entry['__meta']).to include(
        'tabUuid' => 'tab-123',
        'visitId' => 'visit-456',
        'batchId' => 'parent-789',
        'method' => 'GET',
        'status' => 200,
        'requestType' => 'navigate',
        'component' => 'TestComponent'
      )
      expect(entry.dig('__meta', 'url')).to eq("http://www.example.com#{props_path}")
      expect(entry.dig('__meta', 'timestamp')).to be_present
      expect(entry.dig('__meta', 'serverTimingMs')).to be_a(Numeric)
      expect(entry.dig('http', 'requestHeaders')).to be_a(Hash)
      expect(entry.dig('http', 'responseHeaders', InertiaRails::DevTools::ID_HEADER)).to eq(id)
      expect(entry.dig('http', 'responseBody', 'status')).to eq('present')
      expect(entry.dig('http', 'responseBody', 'value', 'component')).to eq('TestComponent')
      expect(entry['props']).to be_a(Hash)
      expect(entry['propValues']).to be_a(Hash)
      expect(entry['route']).to include('uri' => props_path)
      expect(entry.dig('route', 'action')).to match(/#props\z/)
      expect(entry).to include('renderSource' => nil, 'componentPath' => nil)
      expect(InertiaRails::DevTools.store.all.one?).to be(true)
    end

    it 'captures and redacts Inertia request bodies' do
      post redirect_test_path,
           params: { password: 'secret', name: 'Alice' },
           headers: { 'X-Inertia' => 'true' }

      entry = InertiaRails::DevTools.store.fetch(response.headers[InertiaRails::DevTools::ID_HEADER])

      expect(entry.dig('http', 'requestBody')).to eq(
        'status' => 'present',
        'value' => { 'password' => '[REDACTED]', 'name' => 'Alice' }
      )
    end

    it 'classifies initial, partial, deferred, poll, and prefetch requests' do
      get empty_test_path
      initial_id = response.headers[InertiaRails::DevTools::ID_HEADER]

      get empty_test_path, headers: {
        'X-Inertia' => 'true',
        'X-Inertia-Partial-Component' => 'EmptyTestComponent',
      }
      partial_id = response.headers[InertiaRails::DevTools::ID_HEADER]

      get empty_test_path, headers: {
        'X-Inertia' => 'true',
        'X-Inertia-Partial-Component' => 'EmptyTestComponent',
        'X-Inertia-Devtools-Deferred' => '1',
      }
      deferred_id = response.headers[InertiaRails::DevTools::ID_HEADER]

      get empty_test_path, headers: {
        'X-Inertia' => 'true',
        'X-Inertia-Devtools-Poll' => '1',
      }
      poll_id = response.headers[InertiaRails::DevTools::ID_HEADER]

      get empty_test_path, headers: {
        'X-Inertia' => 'true',
        'Purpose' => 'prefetch',
      }
      prefetch_id = response.headers[InertiaRails::DevTools::ID_HEADER]

      expect(recorded_type(initial_id)).to eq('initial')
      expect(recorded_type(partial_id)).to eq('partial')
      expect(recorded_type(deferred_id)).to eq('deferred')
      expect(recorded_type(poll_id)).to eq('poll')
      expect(recorded_type(prefetch_id)).to eq('prefetch')
    end

    it 'returns 404 for missing, malformed, and traversal-like IDs' do
      get "/_inertia/devtools/entries/#{SecureRandom.uuid}"
      expect(response).to have_http_status(:not_found)

      get '/_inertia/devtools/entries/not-an-entry-id'
      expect(response).to have_http_status(:not_found)

      get '/_inertia/devtools/entries/../secret'
      expect(response).to have_http_status(:not_found)
    end

    it 'lists and filters recorded entries' do
      get empty_test_path
      get empty_test_path, headers: {
        'X-Inertia' => 'true',
        'X-Inertia-Partial-Component' => 'EmptyTestComponent',
      }
      get empty_test_path, headers: {
        'X-Inertia' => 'true',
        'X-Inertia-Devtools-Poll' => '1',
      }

      get '/_inertia/devtools/entries', params: { type: 'partial,poll', limit: 1 }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.length).to eq(1)
      expect(%w[partial poll]).to include(response.parsed_body.dig(0, '__meta', 'requestType'))
    end
  end

  context 'when enabled but unauthorized' do
    with_inertia_config(
      devtools_enabled: true,
      devtools_authorize: ->(_request) { false }
    )

    it 'does not record application responses and forbids entry reads' do
      get empty_test_path

      expect(response.headers[InertiaRails::DevTools::ID_HEADER]).to be_nil
      expect(InertiaRails::DevTools.store.all).to be_empty

      get "/_inertia/devtools/entries/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'with a small entry limit' do
    with_inertia_config(
      devtools_enabled: true,
      devtools_authorize: ->(_request) { true },
      devtools_max_entries: 2
    )

    it 'evicts the oldest entries' do
      ids = 3.times.map do
        get empty_test_path, headers: { 'X-Inertia' => 'true' }
        response.headers[InertiaRails::DevTools::ID_HEADER]
      end

      expect(InertiaRails::DevTools.store.all.map { |entry| entry.dig('__meta', 'id') }).to eq(ids.last(2))

      get "/_inertia/devtools/entries/#{ids.first}"
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'with a short entry lifetime' do
    with_inertia_config(
      devtools_enabled: true,
      devtools_authorize: ->(_request) { true },
      devtools_entry_ttl: 1
    )

    it 'expires old entries' do
      get empty_test_path, headers: { 'X-Inertia' => 'true' }
      id = response.headers[InertiaRails::DevTools::ID_HEADER]

      travel 2.seconds do
        get "/_inertia/devtools/entries/#{id}"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  def recorded_type(id)
    InertiaRails::DevTools.store.fetch(id).dig('__meta', 'requestType')
  end
end
