# frozen_string_literal: true

require 'tmpdir'

RSpec.describe 'InertiaRails DevTools', type: :request do
  let(:storage_path) { Dir.mktmpdir('inertia-devtools') }

  around do |example|
    example.run
  ensure
    FileUtils.remove_entry(storage_path) if File.directory?(storage_path)
  end

  def entries
    InertiaRails::Devtools.repository.all
  end

  def entry
    InertiaRails::Devtools.repository.get(entries.first['id'])
  end

  context 'when disabled' do
    with_inertia_config devtools: false

    it 'records nothing and stamps no headers' do
      get devtools_props_path

      expect(response.headers).not_to include('X-Inertia-Devtools-Id')
      expect(response.body).not_to include('data-inertia-devtools-id')
    end

    it 'does not claim the read API paths' do
      expect { get '/_inertia/devtools/entries' }.to raise_error(ActionController::RoutingError)
    end

    it 'rejects devtools options in inertia_config' do
      expect do
        Class.new(ApplicationController) { inertia_config(devtools: true) }
      end.to raise_error(ArgumentError, /cannot be set per controller/)
    end
  end

  context 'when enabled' do
    with_inertia_config devtools: true

    around do |example|
      InertiaRails.configuration.devtools_storage_path = storage_path
      example.run
    ensure
      InertiaRails.configuration.devtools_storage_path = nil
    end

    describe 'discovery' do
      it 'stamps the entry id on every response' do
        get devtools_props_path

        expect(response.headers['X-Inertia-Devtools-Id']).to match(/\A[0-9A-HJKMNP-TV-Z]{26}\z/)
      end

      it 'injects the id into the initial page load' do
        get devtools_props_path

        id = response.headers['X-Inertia-Devtools-Id']
        expect(response.body).to include(
          %(<script data-inertia-devtools-id="" type="application/json">"#{id}"</script>)
        )
      end

      it 'leaves the tag out of Inertia responses' do
        get devtools_props_path, headers: { 'X-Inertia' => true }

        expect(response.body).not_to include('data-inertia-devtools-id')
      end

      it 'leaves the tag out of plain HTML responses' do
        app = ->(_env) { [200, { 'content-type' => 'text/html' }, ['<html><body>Plain</body></html>']] }
        env = Rack::MockRequest.env_for('/plain')
        _status, _headers, body = InertiaRails::Middleware.new(app).call(env)

        expect(body.each.to_a.join).not_to include('data-inertia-devtools-id')
        body.close
      end

      # Rack::ETag will not recompute a digest the app set itself, so a mutated body
      # would be served under a stale validator and revalidate to a 304 without the tag.
      it 'leaves a response carrying a validator alone' do
        get devtools_cached_path

        expect(response.headers['ETag']).to be_present
        expect(response.body).not_to include('data-inertia-devtools-id')
        expect(response.headers['X-Inertia-Devtools-Id']).to be_present
      end

      it 'does not mistake an unbuffered response stream for a body' do
        streamer = Object.new
        streamer.define_singleton_method(:each) { |&block| block.call('<html><body>real</body></html>') }
        rack_response = ActionDispatch::Response.new(200, { 'Content-Type' => 'text/html' })
        rack_response.body = streamer
        body = rack_response.to_a.last

        expect(InertiaRails::Devtools.buffered_body({}, body)).to be_nil
      end

      it 'skips configured path patterns without a leading slash' do
        InertiaRails.configuration.devtools_except = ['devtools_plain']

        get devtools_plain_path

        expect(response.headers).not_to include('X-Inertia-Devtools-Id')
        expect(entries).to be_empty
      ensure
        InertiaRails.configuration.devtools_except = []
      end
    end

    describe 'batching' do
      it 'starts a new batch on a full page visit, ignoring the incoming parent' do
        get devtools_props_path, headers: { 'X-Inertia-Devtools-Parent' => 'ignored' }

        expect(response.headers['X-Inertia-Devtools-Parent-Out']).to eq response.headers['X-Inertia-Devtools-Id']
        expect(entries.first['batchId']).to be_nil
      end

      it 'continues the batch across Inertia requests' do
        get devtools_props_path, headers: { 'X-Inertia' => true, 'X-Inertia-Devtools-Parent' => 'batch-1' }

        expect(response.headers['X-Inertia-Devtools-Parent-Out']).to eq 'batch-1'
        expect(entries.first['batchId']).to eq 'batch-1'
      end

      it 'gives a prefetch its own batch root while recording it under the originating batch' do
        get devtools_props_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Devtools-Parent' => 'batch-1',
          'Purpose' => 'prefetch',
        }

        expect(response.headers['X-Inertia-Devtools-Parent-Out']).to eq response.headers['X-Inertia-Devtools-Id']
        expect(entries.first['batchId']).to eq 'batch-1'
      end
    end

    describe 'request types' do
      it 'records a full page load as initial' do
        get devtools_props_path

        expect(entries.first['requestType']).to eq 'initial'
      end

      it 'records a non-Inertia endpoint as http' do
        get devtools_plain_path

        expect(entries.first['requestType']).to eq 'http'
      end

      it 'records an Inertia visit as navigate' do
        get devtools_props_path, headers: { 'X-Inertia' => true }

        expect(entries.first['requestType']).to eq 'navigate'
      end

      it 'trusts the client for deferred and poll follow-ups' do
        get devtools_props_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Partial-Component' => 'DevtoolsComponent',
          'X-Inertia-Partial-Data' => 'deferred',
          'X-Inertia-Devtools-Deferred' => '1',
        }

        expect(entries.first['requestType']).to eq 'deferred'
      end

      it 'falls back to partial without a devtools intent header' do
        get devtools_props_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Partial-Component' => 'DevtoolsComponent',
          'X-Inertia-Partial-Data' => 'name',
        }

        expect(entries.first['requestType']).to eq 'partial'
      end
    end

    describe 'the entry' do
      subject(:recorded) do
        get devtools_props_path, headers: { 'X-Inertia-Devtools-Tab' => 'tab-1', 'X-Inertia-Devtools-Visit' => 'v-1' }
        entry
      end

      it 'carries the protocol metadata' do
        expect(recorded['__meta']).to include(
          'component' => 'DevtoolsComponent',
          'method' => 'GET',
          'status' => 200,
          'tabUuid' => 'tab-1',
          'visitId' => 'v-1'
        )
        expect(recorded['__meta']['timestamp']).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z/)
        expect(recorded['__meta']['serverTimingMs']).to be_a(Numeric)
      end

      it 'classifies props by wrapper type' do
        expect(recorded['props']['items']).to include('inertiaType' => 'merge', 'mergeDirection' => 'append')
        expect(recorded['props']['name']).to include('shared' => false)
        expect(recorded['props']['nested']).to include('shared' => false)
      end

      it 'badges a deferred prop on the request that delivers it' do
        get devtools_props_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Partial-Component' => 'DevtoolsComponent',
          'X-Inertia-Partial-Data' => 'deferred',
          'X-Inertia-Devtools-Deferred' => '1',
        }

        expect(entry['props']['deferred']).to include('inertiaType' => 'defer', 'deferGroup' => 'default')
      end

      it 'drops the defer type on a manual partial reload' do
        get devtools_props_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Partial-Component' => 'DevtoolsComponent',
          'X-Inertia-Partial-Data' => 'deferred,optional',
        }

        expect(entry['props']['deferred']['inertiaType']).to be_nil
        expect(entry['props']['optional']).to include('inertiaType' => 'optional')
      end

      it 'flags shared props and links them to their share call' do
        expect(recorded['props']['app_name']).to include('shared' => true)
        expect(recorded['props']['app_name']['shareSource']['file'])
          .to end_with('inertia_devtools_test_controller.rb')
      end

      it 'links a rendered prop to the line it is declared on' do
        source = recorded['props']['name']['renderSource']

        expect(source['file']).to end_with('inertia_devtools_test_controller.rb')
        expect(File.readlines(source['file'])[source['line'] - 1]).to include('name:')
      end

      it 'records the resolved values' do
        expect(recorded['propValues']).to include('name' => 'Brandon')
      end

      it 'records the final keys after prop transformation' do
        get prop_transformer_test_path, headers: { 'X-Inertia' => true }
        transformed = entry

        expect(transformed['props'].keys).to include('LOWER_PROP', 'PARENT_HASH')
        expect(transformed['props'].keys).not_to include('lower_prop', 'parent_hash')
        expect(transformed['propValues']).to include(
          'LOWER_PROP' => 'lower_value',
          'PARENT_HASH' => { 'LOWER_CHILD_PROP' => 'lower_child_value' }
        )
      end

      it 'resolves the route' do
        expect(recorded['route']).to include(
          'name' => 'devtools_props',
          'uri' => '/devtools_props',
          'action' => 'InertiaDevtoolsTestController#props'
        )
        expect(recorded['route']['actionSource']['file']).to end_with('inertia_devtools_test_controller.rb')
      end

      it 'captures the page object as the response body' do
        expect(recorded['http']['responseBody']['value']).to include('component' => 'DevtoolsComponent')
      end
    end

    # Route defaults are captured when the routes are drawn, so these need a redraw
    # with recording on — and another one on the way out, so the key does not leak
    # into the route defaults every later example sees.
    describe 'routes drawn while recording' do
      around do |example|
        Rails.application.reload_routes!
        example.run
      ensure
        InertiaRails.configuration.devtools = false
        Rails.application.reload_routes!
      end

      it 'links route-defined renders to the route definition' do
        get inertia_route_path, headers: { 'X-Inertia' => true }
        source = entry['renderSource']

        expect(source['file']).to end_with('config/routes.rb')
        expect(File.readlines(source['file'])[source['line'] - 1]).to include("inertia 'inertia_route'")
      end
    end

    describe 'prop pruning' do
      it 'keeps one row per top-level prop regardless of nesting' do
        get devtools_nested_share_path
        paths = entry['props'].keys

        expect(paths).to include('auth', 'auth.badge', 'plain_nested')
        expect(paths).not_to include('auth.user', 'auth.user.profile.city', 'plain_nested.a.b.c')
        expect(entry['props']['auth.badge']).to include('shared' => false, 'inertiaType' => 'always')
      end

      it 'duplicates only nested values that carry metadata' do
        get devtools_nested_share_path

        expect(entry['propValues']['auth']).to eq(
          'badge' => 'A',
          'user' => { 'id' => 1, 'profile' => { 'city' => 'Portland' } }
        )
        expect(entry['propValues'].slice('auth.badge')).to eq('auth.badge' => 'A')
      end

      it 'keys array paths by their index in the rendered array' do
        get devtools_collection_path
        recorded = entry
        rows = recorded['http']['responseBody']['value']['props']['rows']

        expect(rows.length).to eq 2
        expect(recorded['propValues']['rows.0.tag']).to eq rows[0]['tag']
        expect(recorded['propValues']['rows.1.tag']).to eq rows[1]['tag']
      end
    end

    describe 'redaction' do
      it 'redacts sensitive props, headers, and query parameters' do
        get "#{devtools_props_path}?token=leaked", headers: { 'Authorization' => 'Bearer x', 'Cookie' => 'a=b' }
        recorded = entry

        expect(recorded['propValues']['password']).to eq '[REDACTED]'
        expect(recorded['http']['requestHeaders']['authorization']).to eq '[REDACTED]'
        expect(recorded['http']['requestHeaders']['cookie']).to eq '[REDACTED]'
        expect(recorded['__meta']['url']).to include('token=%5BREDACTED%5D')
      end

      it 'redacts keys inside a captured non-Inertia response body' do
        get devtools_plain_path
        expect(entry['http']['responseBody']['value']).to eq('ok' => true, 'token' => '[REDACTED]')
      end

      it 'omits a non-Inertia response body it cannot redact by key' do
        get non_inertiafied_path

        expect(entry['http']['responseBody']).to eq('status' => 'omitted', 'reason' => 'unredactable')
      end

      it 'redacts the query of a full-page location redirect' do
        get "#{devtools_props_path}?token=leaked",
            headers: { 'X-Inertia' => true, 'X-Inertia-Version' => 'stale' }

        expect(response.status).to eq 409
        expect(entry['http']['responseHeaders']['x-inertia-location']).to include('token=%5BREDACTED%5D')
      end

      it 'honors the app filter_parameters list' do
        get devtools_props_path

        expect(entry['propValues']['ssn']).to eq '[REDACTED]'
      end

      it 'redacts nested values recorded under flattened dot paths' do
        get devtools_props_path

        expect(entry['props']['secrets.token']).to include('inertiaType' => 'always')
        expect(entry['propValues']['secrets.token']).to eq '[REDACTED]'
      end

      it 'keeps metadata for props named like sensitive keys' do
        get devtools_props_path

        expect(entry['props']['password']).to include('shared' => false)
      end

      it 'drops an unparseable query instead of persisting it raw' do
        expect(InertiaRails::Devtools::Redaction.redact_url('http://x/?token=%zz'))
          .to eq 'http://x/?[REDACTED]'
      end

      it 'redacts sensitive keys nested in query parameters' do
        get "#{devtools_props_path}?user[token]=leaked"

        expect(entry['__meta']['url']).to include('user%5Btoken%5D=%5BREDACTED%5D')
      end

      it 'redacts the query of URLs carried in headers' do
        post devtools_create_path, headers: { 'X-Inertia' => true, 'Referer' => 'http://ex.com/r?token=leaked' }
        recorded = entry

        expect(recorded['http']['requestHeaders']['referer']).to eq 'http://ex.com/r?token=%5BREDACTED%5D'
        expect(recorded['http']['responseHeaders']['location']).to include('token=%5BREDACTED%5D')
      end

      it 'redacts a raw body Rails did not parse' do
        post devtools_create_path, params: '{"password":"hunter2"}',
                                   headers: { 'X-Inertia' => true, 'CONTENT_TYPE' => 'text/plain' }

        expect(entry['http']['requestBody']).to eq(
          'status' => 'present', 'value' => { 'password' => '[REDACTED]' }
        )
      end

      it 'omits an unstructured body rather than storing it raw' do
        post devtools_create_path, params: 'password=hunter2',
                                   headers: { 'X-Inertia' => true, 'CONTENT_TYPE' => 'text/plain' }

        expect(entry['http']['requestBody']).to eq('status' => 'omitted', 'reason' => 'unredactable')
      end
    end

    describe 'unserializable values' do
      it 'replaces a leaf instead of suppressing recording' do
        get devtools_plain_path
        get devtools_plain_path, headers: { 'X-Weird' => (+"caf\xE9").force_encoding('ASCII-8BIT') }
        get devtools_plain_path

        expect(entries.length).to eq 3
      end

      it 'replaces non-finite floats and invalid encodings' do
        sanitized = InertiaRails::Devtools::Redaction.sanitize(
          [Float::NAN, Float::INFINITY, (+"caf\xE9").force_encoding('UTF-8')]
        )

        expect(sanitized).to eq(['[UNSERIALIZABLE]'] * 3)
        expect { JSON.generate(sanitized) }.not_to raise_error
      end
    end

    describe 'redirects' do
      it 'records the redirect target' do
        post devtools_create_path, headers: { 'X-Inertia' => true }

        expect(entries.first['status']).to eq 302
        expect(entry['__meta']['redirectLocation']).to include('/devtools_props')
      end

      it 'omits a non-Inertia write body' do
        post devtools_create_path, params: { password: 'hunter2' }

        expect(entry['http']['requestBody']).to eq('status' => 'omitted', 'reason' => 'non-inertia-request')
      end
    end

    describe 'the read API' do
      # Outside development the API is gated, and the test environment is no exception.
      around do |example|
        InertiaRails.configuration.devtools_authorize = -> { true }
        example.run
      ensure
        InertiaRails.configuration.devtools_authorize = nil
      end

      before { get devtools_props_path }

      it 'forbids the request when no gate is configured' do
        InertiaRails.configuration.devtools_authorize = nil

        get '/_inertia/devtools/entries'

        expect(response.status).to eq 403
      end

      it 'forbids the request when the gate denies it' do
        InertiaRails.configuration.devtools_authorize = -> { session[:admin] }

        get '/_inertia/devtools/entries'

        expect(response.status).to eq 403
      end

      it 'lists entry metadata newest first' do
        get devtools_plain_path
        get '/_inertia/devtools/entries'

        listed = response.parsed_body
        expect(listed.length).to eq 2
        expect(listed.first['requestType']).to eq 'http'
        expect(listed.map { |item| item['id'] }).to eq(listed.map { |item| item['id'] }.sort.reverse)
      end

      it 'filters by component and type' do
        get devtools_plain_path

        get '/_inertia/devtools/entries', params: { component: 'DevtoolsComponent' }
        expect(response.parsed_body.length).to eq 1

        get '/_inertia/devtools/entries', params: { exclude: 'http' }
        expect(response.parsed_body.length).to eq 1
      end

      it 'clamps numeric limits to at least one' do
        get devtools_plain_path

        get '/_inertia/devtools/entries', params: { limit: 1 }
        expect(response.parsed_body.length).to eq 1

        get '/_inertia/devtools/entries', params: { limit: 0 }
        expect(response.parsed_body.length).to eq 1

        get '/_inertia/devtools/entries', params: { limit: -1 }
        expect(response.parsed_body.length).to eq 1
      end

      it 'applies an offset' do
        get devtools_plain_path

        get '/_inertia/devtools/entries', params: { offset: 1 }

        expect(response.parsed_body.length).to eq 1
        expect(response.parsed_body.first['requestType']).to eq 'initial'
      end

      it 'returns a single entry' do
        get "/_inertia/devtools/entries/#{entries.first['id']}"

        expect(response.parsed_body['__meta']['component']).to eq 'DevtoolsComponent'
      end

      it '404s an unknown entry' do
        get "/_inertia/devtools/entries/#{InertiaRails::Devtools::Ulid.generate}"

        expect(response.status).to eq 404
      end

      it 'does not record itself' do
        get '/_inertia/devtools/entries'

        expect(entries.length).to eq 1
      end
    end

    describe 'storage limits' do
      it 'keeps only the newest entries for a tab' do
        InertiaRails.configuration.devtools_limit = 2
        3.times { get devtools_props_path, headers: { 'X-Inertia-Devtools-Tab' => 'tab-1' } }

        expect(entries.length).to eq 2
      ensure
        InertiaRails.configuration.devtools_limit = 100
      end

      it 'keeps only the newest entries that arrived without a tab' do
        InertiaRails.configuration.devtools_limit = 2
        3.times { get devtools_props_path }

        expect(entries.length).to eq 2
      ensure
        InertiaRails.configuration.devtools_limit = 100
      end

      it 'stops touching storage after a write failure' do
        repository = InertiaRails::Devtools::EntriesRepository.new(path: File.join(storage_path, 'nested'))
        allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::EACCES)
        allow(InertiaRails::Devtools).to receive(:report)

        3.times do
          repository.record(InertiaRails::Devtools::Ulid.generate, {})
          repository.prune_if_due
        end

        expect(InertiaRails::Devtools).to have_received(:report).once
      end

      it 'caps total entries even without a tab header' do
        InertiaRails.configuration.devtools_max_entries = 2
        3.times { get devtools_props_path }

        expect(entries.length).to eq 2
      ensure
        InertiaRails.configuration.devtools_max_entries = 0
      end

      it 'preserves large Inertia page and prop payloads' do
        get devtools_oversized_path
        recorded = entry

        expect(recorded['http']['responseBody']['status']).to eq 'present'
        expect(recorded.dig('http', 'responseBody', 'value', 'props', 'blob').length).to eq 300_000
        expect(recorded['propValues']['blob'].length).to eq 300_000
        expect(recorded['props']).to include('blob')
      end

      it 'honors a fractional ttl' do
        InertiaRails.configuration.devtools_ttl = 0.5
        InertiaRails.configuration.devtools_prune_interval = 0
        2.times { get devtools_props_path }

        expect(entries.length).to eq 2
      ensure
        InertiaRails.configuration.devtools_ttl = 24
        InertiaRails.configuration.devtools_prune_interval = 300
      end
    end

    describe 'exceptions' do
      it 'records a request whose action raises' do
        expect { get devtools_boom_path }.to raise_error(RuntimeError, 'devtools boom')

        expect(entries.first['status']).to eq 500
        expect(entry['__meta']['error']).to eq('class' => 'RuntimeError', 'message' => 'devtools boom')
        expect(entry['http']['responseBody']).to eq('status' => 'omitted', 'reason' => 'exception')
      end

      it 'stamps the response rendered by Rails exception handling' do
        env_config = Rails.application.env_config
        original = env_config['action_dispatch.show_exceptions']
        env_config['action_dispatch.show_exceptions'] = Rails.version < '7.1' ? true : :all

        get devtools_boom_path

        id = response.headers['X-Inertia-Devtools-Id']

        expect(response).to have_http_status(:internal_server_error)
        expect(id).to match(/\A[0-9A-HJKMNP-TV-Z]{26}\z/)
        expect(InertiaRails::Devtools.repository.get(id).dig('__meta', 'error', 'message')).to eq 'devtools boom'
      ensure
        env_config['action_dispatch.show_exceptions'] = original
      end
    end

    it 'emits an empty route object when no Rails route handled the response' do
      app = ->(_env) { [401, { 'content-type' => 'text/plain' }, ['blocked']] }
      env = Rack::MockRequest.env_for('/blocked')
      _status, headers, body = InertiaRails::Middleware.new(app).call(env)
      body.close

      id = headers[InertiaRails::Devtools::Headers.response_keys.first]
      expect(InertiaRails::Devtools.repository.get(id)['route']).to eq(
        'name' => nil, 'uri' => '', 'action' => nil
      )
    end

    it 'returns an absolute component path' do
      root = File.join(storage_path, 'pages')
      file = File.join(root, 'AbsoluteComponent.vue')
      FileUtils.mkdir_p(root)
      File.write(file, '')
      InertiaRails.configuration.devtools_component_paths = [root]

      expect(InertiaRails::Devtools::ComponentPathLocator.resolve('AbsoluteComponent')).to eq file
    ensure
      InertiaRails.configuration.devtools_component_paths = nil
    end

    it 'rebuilds a corrupt metadata index from entry files' do
      get devtools_props_path
      id = entries.first['id']
      File.write(File.join(storage_path, '_meta.json'), '{ invalid json')

      expect(entries.map { |meta| meta['id'] }).to include(id)
      expect(JSON.parse(File.read(File.join(storage_path, '_meta.json')))).to have_key(id)
    end

    it 'rejects invalid storage entry ids' do
      repository = InertiaRails::Devtools::EntriesRepository.new(path: storage_path)

      expect { repository.record('../secret', {}) }.to raise_error(ArgumentError, /Invalid/)
    end

    it 'never breaks the response when recording fails' do
      allow(InertiaRails::Devtools::EntryBuilder).to receive(:new).and_raise('boom')

      get devtools_props_path

      expect(response.status).to eq 200
    end
  end
end
