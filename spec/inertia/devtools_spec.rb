# frozen_string_literal: true

require 'tmpdir'

RSpec.describe 'InertiaRails DevTools', type: :request do
  def entries
    InertiaRails::Devtools.store.list
  end

  def entry
    InertiaRails::Devtools.store.read(entries.first['id'])
  end

  def in_development
    InertiaRails.configuration.devtools.authorize = nil
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('development'))
  end

  context 'when disabled' do
    with_devtools_config enabled: false

    it 'records nothing and stamps no headers' do
      get devtools_props_path

      expect(response.headers).not_to include('x-inertia-devtools-id')
      expect(response.body).not_to include('data-inertia-devtools-id')
    end

    it 'does not claim the read API paths' do
      expect { get '/_inertia/devtools/entries' }.to raise_error(ActionController::RoutingError)
    end
  end

  context 'when enabled' do
    with_devtools_config enabled: true, authorize: -> { true }

    around do |example|
      Dir.mktmpdir('inertia-devtools') do |dir|
        InertiaRails.configuration.devtools.storage_path = dir
        example.run
      end
    ensure
      InertiaRails.configuration.devtools.storage_path = InertiaRails::Devtools::Config::DEFAULTS[:storage_path]
    end

    let(:storage_path) { InertiaRails.configuration.devtools.storage_path }

    describe 'discovery' do
      it 'injects the id into the initial page load' do
        get devtools_props_path

        id = response.headers['x-inertia-devtools-id']
        expect(response.body).to include(
          %(<script data-inertia-devtools-id="" type="application/json">"#{id}"</script>)
        )
      end

      it 'reports the prefix the app is mounted under' do
        get devtools_props_path, env: { 'SCRIPT_NAME' => '/sub' }

        expect(response.headers['x-inertia-devtools-base-path']).to eq '/sub'
        expect(response.body).to include(%(<script data-inertia-devtools-id="" data-inertia-devtools-base-path="/sub"))
      end

      it 'reports no base path at the root' do
        get devtools_props_path

        expect(response.headers).not_to include('x-inertia-devtools-base-path')
        expect(response.body).not_to include('data-inertia-devtools-base-path')
      end

      it 'leaves out what the browser fetches for images, scripts, and sockets' do
        %w[image script websocket].each do |destination|
          get devtools_props_path, headers: { 'Sec-Fetch-Dest' => destination }

          expect(response.headers).not_to include('x-inertia-devtools-id')
        end
        get devtools_props_path, headers: { 'Sec-Fetch-Dest' => 'document' }

        expect(entries.length).to eq 1
      end

      it 'reads a redirect location a Rack app returns as an array' do
        in_development
        app = ->(_env) { [302, { 'location' => ['/next'] }, []] }
        _status, headers, _body = InertiaRails::Devtools::Middleware.new(app).call(Rack::MockRequest.env_for('/old'))

        entry = InertiaRails::Devtools.store.read(headers['x-inertia-devtools-id'])
        expect(entry['__meta']['redirectLocation']).to eq '/next'
      end

      context 'with server-side rendering' do
        with_inertia_config ssr_enabled: true, ssr_url: 'http://localhost:13714'

        before do
          ssr = instance_double(Net::HTTPOK, body: { head: [], body: '<div id="app">SSR</div>' }.to_json, code: '200')
          allow(ssr).to receive(:is_a?) { |klass| [Net::HTTPSuccess, Net::HTTPOK].include?(klass) }
          http = instance_double(Net::HTTP, post: ssr)
          allow(Net::HTTP).to receive(:start).and_yield(http)
        end

        it 'renders the tag after the server-rendered page' do
          get devtools_props_path

          expect(response.body).to include(%(<div id="app">SSR</div><script data-inertia-devtools-id=""))
        end
      end

      it 'records the headers the browser receives, cookies redacted' do
        post '/redirect_with_inertia_errors', headers: { 'X-Inertia' => true }

        expect(entry['http']['responseHeaders']).to include('set-cookie' => '[REDACTED]')
      end

      context 'with paths to skip' do
        with_devtools_config except: ['devtools_plain', %r{\A/devtools_kinds}]

        it 'skips paths matched by a glob or a regexp' do
          get devtools_plain_path
          expect(response.headers).not_to include('x-inertia-devtools-id')

          get devtools_kinds_path
          expect(response.headers).not_to include('x-inertia-devtools-id')
          expect(entries).to be_empty
        end
      end
    end

    describe 'batching' do
      it 'starts a new batch on a full page visit, ignoring the incoming parent' do
        get devtools_props_path, headers: { 'X-Inertia-Devtools-Parent' => 'ignored' }

        expect(response.headers['x-inertia-devtools-parent-out']).to eq response.headers['x-inertia-devtools-id']
        expect(entries.first['batchId']).to be_nil
      end

      it 'continues the batch across Inertia requests' do
        get devtools_props_path, headers: { 'X-Inertia' => true, 'X-Inertia-Devtools-Parent' => 'batch-1' }

        expect(response.headers['x-inertia-devtools-parent-out']).to eq 'batch-1'
        expect(entries.first['batchId']).to eq 'batch-1'
      end

      it 'gives a prefetch its own batch root while recording it under the originating batch' do
        get devtools_props_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Devtools-Parent' => 'batch-1',
          'Purpose' => 'prefetch',
        }

        expect(response.headers['x-inertia-devtools-parent-out']).to eq response.headers['x-inertia-devtools-id']
        expect(entries.first['batchId']).to eq 'batch-1'
      end
    end

    it 'derives the request type from the request headers' do
      inertia = { 'X-Inertia' => true }
      partial = inertia.merge('X-Inertia-Partial-Component' => 'DevtoolsComponent', 'X-Inertia-Partial-Data' => 'name')
      requests = {
        'initial' => {},
        'navigate' => inertia.merge('Precognition' => ''),
        'precognition' => inertia.merge('Precognition' => 'true'),
        'deferred' => partial.merge('X-Inertia-Devtools-Deferred' => '1'),
        'poll' => partial.merge('X-Inertia-Devtools-Poll' => '1'),
        'partial' => partial,
        'prefetch' => inertia.merge('Purpose' => 'Prefetch'),
      }

      recorded = requests.transform_values do |headers|
        get devtools_props_path, headers: headers
        entries.first['requestType']
      end
      get devtools_plain_path

      expect(recorded).to eq(requests.to_h { |type, _| [type, type] })
      expect(entries.first['requestType']).to eq 'http'
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

      it 'badges every prop kind' do
        get devtools_kinds_path, headers: { 'X-Inertia' => true }
        badges = entry['props']

        expect(badges['plain']).to include('inertiaType' => nil)
        expect(badges['always']).to include('inertiaType' => 'always')
        expect(badges['items']).to include('inertiaType' => 'merge', 'mergeDirection' => 'append')
        expect(badges['prepended']).to include('inertiaType' => 'merge', 'mergeDirection' => 'prepend')
        expect(badges['matched']).to include('inertiaType' => 'merge', 'deepMerge' => true)
        expect(badges['deep']).to include('inertiaType' => 'merge', 'deepMerge' => true)
        expect(badges['settings']).to include('inertiaType' => 'once', 'once' => true)
        expect(badges['users']).to include('inertiaType' => 'scroll', 'mergeDirection' => 'append')
      end

      it 'keeps the group of a deferred scroll prop' do
        get devtools_kinds_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Partial-Component' => 'DevtoolsComponent',
          'X-Inertia-Partial-Data' => 'more_users',
          'X-Inertia-Devtools-Deferred' => '1',
        }

        expect(entry['props']['more_users']).to include('inertiaType' => 'scroll', 'deferGroup' => 'custom')
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

      it 'keeps a rescued deferred prop, which has no value in the page' do
        get devtools_rescued_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Partial-Component' => 'DevtoolsComponent',
          'X-Inertia-Partial-Data' => 'failing',
          'X-Inertia-Devtools-Deferred' => '1',
        }

        expect(entry['props']['failing']).to include('inertiaType' => 'defer', 'rescued' => true)
        expect(entry['propValues']).not_to include('failing')
      end

      it 'flags a prop the visit resets' do
        get devtools_kinds_path, headers: {
          'X-Inertia' => true,
          'X-Inertia-Partial-Component' => 'DevtoolsComponent',
          'X-Inertia-Partial-Data' => 'items',
          'X-Inertia-Reset' => 'items',
        }

        expect(entry['props']['items']).to include('inertiaType' => 'merge', 'reset' => true)
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

      it 'links a nested prop of a shared hash to its share, not to the render' do
        get devtools_nested_share_path
        badge = entry['props']['auth.badge']

        expect(badge['shareSource']['file']).to end_with('inertia_devtools_test_controller.rb')
        expect(badge).not_to have_key('renderSource')
      end

      it 'treats a shared key the render replaced as a rendered prop' do
        get merge_shared_path, headers: { 'X-Inertia' => true }
        nested = entry['props']['nested']

        expect(nested).to include('shared' => false)
        expect(nested).not_to have_key('shareSource')
        expect(nested['renderSource']['file']).to end_with('inertia_merge_shared_controller.rb')
      end

      it 'flags shared props and links them to their share call' do
        expect(recorded['props']['app_name']).to include('shared' => true)
        expect(recorded['props']['app_name']['shareSource']['file'])
          .to end_with('inertia_devtools_test_controller.rb')
      end

      it 'links a shared prop overridden in a subclass to the override' do
        get share_with_inherited_path
        recorded = entry

        expect(recorded['propValues']['name']).to eq 'No Longer Brandon'
        expect(recorded['props']['name']['shareSource']['file']).to end_with('inertia_child_share_test_controller.rb')
      end

      it 'links a prop shared from a block to the line of its key', if: InertiaRails::Devtools::SourceLocator.prism? do
        get share_path
        source = entry['props']['position']['shareSource']

        expect(source['file']).to end_with('inertia_share_test_controller.rb')
        expect(File.readlines(source['file'])[source['line'] - 1]).to include('position:')
      end

      it 'links a prop whose key cannot be found to the render call' do
        get devtools_collection_path
        recorded = entry

        expect(recorded['props']['rows.1.tag']['renderSource']).to eq recorded['renderSource']
      end

      it 'links an implicit render to its action, not to a filter around it' do
        get devtools_implicit_path, headers: { 'X-Inertia' => true }
        source = entry['renderSource']

        expect(source['file']).to end_with('inertia_devtools_implicit_controller.rb')
        expect(File.readlines(source['file'])[source['line'] - 1]).to include('def show')
      end

      it 'links a rendered prop to the line it is declared on', if: InertiaRails::Devtools::SourceLocator.prism? do
        source = recorded['props']['name']['renderSource']

        expect(source['file']).to end_with('inertia_devtools_test_controller.rb')
        expect(File.readlines(source['file'])[source['line'] - 1]).to include('name:')
      end

      it 'resolves the route' do
        expect(recorded['route']).to include(
          'uri' => '/devtools_props',
          'action' => 'InertiaDevtoolsTestController#props'
        )
        expect(recorded['route']['actionSource']['file']).to end_with('inertia_devtools_test_controller.rb')
      end

      context 'with the page file in a configured directory' do
        with_devtools_config component_paths: nil

        it 'links the page file' do
          Dir.mktmpdir do |root|
            file = File.join(root, 'DevtoolsComponent.vue')
            File.write(file, '')
            InertiaRails.configuration.devtools.component_paths = [root]

            expect(recorded['componentPath']).to eq file
          end
        end
      end
    end

    it 'names the matched route', if: Rails.gem_version >= Gem::Version.new('8.1') do
      get devtools_props_path

      expect(entry['route']['name']).to eq 'devtools_props'
    end

    describe 'routes drawn with source locations', if: Rails.gem_version >= Gem::Version.new('8.1') do
      around do |example|
        ActionDispatch::Routing::Mapper.route_source_locations = true
        Rails.application.reload_routes!
        example.run
      ensure
        ActionDispatch::Routing::Mapper.route_source_locations = false
        Rails.application.reload_routes!
      end

      it 'links route-defined renders to the route definition' do
        get inertia_route_path, headers: { 'X-Inertia' => true }
        source = entry['renderSource']

        expect(source['file']).to end_with('config/routes.rb')
        expect(File.readlines(source['file'])[source['line'] - 1]).to include("inertia 'inertia_route'")
        expect(entry['route']['actionSource']).to eq source
      end
    end

    describe 'prop pruning' do
      it 'keeps a row per top-level prop and per nested prop that carries metadata' do
        get devtools_nested_share_path
        recorded = entry

        expect(recorded['props'].keys).to include('auth', 'auth.badge', 'plain_nested')
        expect(recorded['props'].keys).not_to include('auth.user', 'auth.user.profile.city', 'plain_nested.a.b.c')
        expect(recorded['props']['auth.badge']).to include('shared' => false, 'inertiaType' => 'always')
        expect(recorded['propValues']).to include(
          'auth' => { 'badge' => 'A', 'user' => { 'id' => 1, 'profile' => { 'city' => 'Portland' } } },
          'auth.badge' => 'A'
        )
        expect(recorded['propValues'].keys).not_to include('auth.user')
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
      it 'omits a JSON response that is not valid UTF-8' do
        get devtools_invalid_json_path

        expect(entry['http']['responseBody']).to eq('status' => 'omitted', 'reason' => 'unserializable')
      end

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

        expect(entry['http']['responseBody']).to eq('status' => 'omitted', 'reason' => 'non-inertia-response')
      end

      it 'applies the app filter_parameters to request parameters and URLs, not to props' do
        post devtools_create_path, params: { ssn: '123', name: 'Ann' }.to_json,
                                   headers: { 'X-Inertia' => true, 'CONTENT_TYPE' => 'application/json' }
        expect(entry.dig('http', 'requestBody', 'value')).to include('ssn' => '[REDACTED]', 'name' => 'Ann')

        get "#{devtools_props_path}?ssn=123"
        recorded = entry

        expect(recorded['__meta']['url']).to end_with('?ssn=%5BREDACTED%5D')
        expect(recorded['propValues']['ssn']).to eq '123-45-6789'
      end

      it 'records a URL with nothing to redact exactly as requested' do
        get "#{devtools_props_path}?filter%5Bname%5D=a%20b&sort=-id#top"

        expect(entry['__meta']['url']).to end_with('?filter%5Bname%5D=a%20b&sort=-id')
        expect(InertiaRails::Devtools::Redaction.redact_url('/p?q=a+b&x[]=1#f')).to eq '/p?q=a+b&x[]=1#f'
      end

      it 'redacts nested values recorded under flattened dot paths' do
        get devtools_props_path

        expect(entry['props']['secrets.token']).to include('inertiaType' => 'always')
        expect(entry['propValues']['secrets.token']).to eq '[REDACTED]'
      end

      it 'redacts sensitive keys nested in query parameters' do
        get "#{devtools_props_path}?user%5Btoken%5D=leaked"

        expect(entry['__meta']['url']).to end_with('?user%5Btoken%5D=%5BREDACTED%5D')
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

      it 'redacts form parameters and summarizes uploads' do
        post devtools_create_path, headers: { 'X-Inertia' => true },
                                   params: { password: 'hunter2', file: Rack::Test::UploadedFile.new(__FILE__, 'text/plain') }

        expect(entry.dig('http', 'requestBody', 'value')).to eq(
          'password' => '[REDACTED]',
          'file' => { 'name' => File.basename(__FILE__), 'size' => File.size(__FILE__), 'mimeType' => 'text/plain' }
        )
      end

      it 'records the JSON body the client sent, not the params Rails wrapped' do
        post devtools_create_path, params: { name: 'Ann' }.to_json,
                                   headers: { 'X-Inertia' => true, 'CONTENT_TYPE' => 'application/json' }

        expect(entry['http']['requestBody']).to eq('status' => 'present', 'value' => { 'name' => 'Ann' })
      end

      it 'omits an unstructured body rather than storing it raw' do
        post devtools_create_path, params: 'password=hunter2',
                                   headers: { 'X-Inertia' => true, 'CONTENT_TYPE' => 'text/plain' }

        expect(entry['http']['requestBody']).to eq('status' => 'omitted', 'reason' => 'unserializable')
      end
    end

    describe 'values JSON cannot hold' do
      it 'records a header whose bytes are not valid UTF-8, with those bytes replaced' do
        get devtools_plain_path, headers: { 'X-Weird' => (+"caf\xE9").force_encoding('ASCII-8BIT') }

        expect(entry['http']['requestHeaders']['x-weird']).to eq "caf\uFFFD"
      end

      it 'drops the entry, not the response, when a body holds a number JSON cannot write' do
        allow(InertiaRails::Devtools).to receive(:report)

        post devtools_create_path, params: '{"amount":1e400}',
                                   headers: { 'X-Inertia' => true, 'CONTENT_TYPE' => 'application/json' }

        expect(response).to have_http_status(:found)
        expect(entries).to be_empty
        expect(InertiaRails::Devtools).to have_received(:report).once
      end
    end

    describe 'redirects' do
      context 'with the location header redacted' do
        with_devtools_config redact_headers: %w[location]

        it 'redacts the redirect location the same way' do
          post devtools_create_path, headers: { 'X-Inertia' => true }

          expect(entry['__meta']['redirectLocation']).to eq '[REDACTED]'
        end
      end

      it 'records a redirect whose location is not valid UTF-8' do
        in_development
        app = ->(_env) { [302, { 'location' => (+"/next\xFF").force_encoding('ASCII-8BIT') }, []] }
        _status, headers, _body = InertiaRails::Devtools::Middleware.new(app).call(Rack::MockRequest.env_for('/old'))

        recorded = InertiaRails::Devtools.store.read(headers['x-inertia-devtools-id'])
        expect(recorded['__meta']['redirectLocation']).to eq "/next\uFFFD"
      end

      it 'records the redirect target and an empty body' do
        post devtools_create_path, headers: { 'X-Inertia' => true }
        recorded = entry

        expect(recorded['__meta']).to include('status' => 302)
        expect(recorded['__meta']['redirectLocation']).to include('/devtools_props')
        expect(recorded['http']['responseBody']).to eq('status' => 'empty')
      end

      it 'omits a non-Inertia write body' do
        post devtools_create_path, params: { password: 'hunter2' }

        expect(entry['http']['requestBody']).to eq('status' => 'omitted', 'reason' => 'non-inertia-request')
      end
    end

    describe 'the gate' do
      it 'looks up no share lines for requests it rejects' do
        InertiaRails.configuration.devtools.authorize = -> { false }
        allow(InertiaRails::Devtools::SourceLocator).to receive(:key_sources).and_call_original

        get share_path

        expect(InertiaRails::Devtools::SourceLocator).not_to have_received(:key_sources)
      end

      it 'records only what it approves, deciding in the controller that handled the request' do
        InertiaRails.configuration.devtools.authorize = -> { action_name == 'props' }

        get devtools_plain_path
        expect(response.headers).not_to include('x-inertia-devtools-id')

        get devtools_props_path
        expect(response.body).to include('data-inertia-devtools-id')
        expect(entries.map { |meta| meta['component'] }).to eq ['DevtoolsComponent']
      end

      it 'records nothing when it raises, and keeps the response' do
        allow(InertiaRails::Devtools).to receive(:report)
        InertiaRails.configuration.devtools.authorize = -> { raise 'gate' }

        get devtools_props_path

        expect(response.status).to eq 200
        expect(response.headers).not_to include('x-inertia-devtools-id')
        expect(entries).to be_empty
        expect(InertiaRails::Devtools).to have_received(:report).once
      end

      it 'records nothing outside development without one' do
        InertiaRails.configuration.devtools.authorize = nil

        get devtools_props_path

        expect(response.headers).not_to include('x-inertia-devtools-id')
        expect(entries).to be_empty
      end

      it 'runs the read API behind the base controller' do
        InertiaRails.configuration.devtools.authorize = -> { is_a?(ApplicationController) }
        get devtools_props_path

        get '/_inertia/devtools/entries'

        expect(response.parsed_body.length).to eq 1
      end
    end

    describe 'the read API' do
      before { get devtools_props_path }

      it 'forbids the request when no gate is configured' do
        InertiaRails.configuration.devtools.authorize = nil

        get '/_inertia/devtools/entries'

        expect(response.status).to eq 403
      end

      it 'forbids the request when the gate denies it' do
        InertiaRails.configuration.devtools.authorize = -> { session[:admin] }

        get '/_inertia/devtools/entries'

        expect(response.status).to eq 403
      end

      it 'is open in development without a gate' do
        in_development

        get '/_inertia/devtools/entries'

        expect(response.status).to eq 200
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
        listed = {
          { component: 'DevtoolsComponent' } => ['initial'],
          { type: 'http' } => ['http'],
          { exclude: 'http' } => ['initial'],
        }

        types = listed.keys.to_h do |params|
          get '/_inertia/devtools/entries', params: params
          [params, response.parsed_body.map { |item| item['requestType'] }]
        end

        expect(types).to eq listed
      end

      it 'reads offset and limit as decimal numbers' do
        get devtools_plain_path

        get '/_inertia/devtools/entries', params: { offset: '0x1' }

        expect(response.parsed_body.length).to eq 2
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

      it 'keeps its own polling out of the log' do
        logged = capture_log { get '/_inertia/devtools/entries' }

        expect(response.status).to eq 200
        expect(logged).to be_empty
        expect(capture_log { get devtools_props_path }).to include('Started GET')
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
        get "/_inertia/devtools/entries/#{InertiaRails::Devtools::EntryStore.generate_id}"

        expect(response.status).to eq 404
      end

      it 'does not record itself' do
        get '/_inertia/devtools/entries'

        expect(entries.length).to eq 1
      end

      it 'keeps its routes out of the app route listing' do
        routes = Rails.application.routes.routes.select { |route| route.path.spec.to_s.start_with?('/_inertia') }

        expect(routes.map(&:internal)).to eq [true, true]
      end

      it 'serves an app without session middleware' do
        in_development
        env = Rack::MockRequest.env_for('/_inertia/devtools/entries')
        status, = InertiaRails::Devtools::EntriesController.action(:index).call(env)

        expect(status).to eq 200
      end

      it 'never writes the app session or cookies' do
        InertiaRails.configuration.devtools.authorize = -> { session[:inertia_errors] || true }
        post '/redirect_with_inertia_errors'

        with_forgery_protection { get '/_inertia/devtools/entries' }
        expect(response.headers['Set-Cookie']).to be_blank

        get '/empty_test', headers: { 'X-Inertia' => true }
        expect(response.parsed_body.dig('props', 'errors')).to eq('uh' => 'oh')
      end
    end

    describe 'storage limits' do
      context 'with a limit of two' do
        with_devtools_config limit: 2

        it 'keeps only the newest entries for a tab' do
          ids = Array.new(3) do
            get devtools_props_path, headers: { 'X-Inertia-Devtools-Tab' => 'tab-1' }
            response.headers['x-inertia-devtools-id']
          end

          expect(entries.map { |meta| meta['id'] }).to eq ids.last(2).reverse
        end

        it 'keeps only the newest entries that arrived without a tab' do
          ids = Array.new(3) do
            get devtools_props_path
            response.headers['x-inertia-devtools-id']
          end

          expect(entries.map { |meta| meta['id'] }).to eq ids.last(2).reverse
        end
      end

      it 'preserves large Inertia page and prop payloads' do
        get devtools_oversized_path
        recorded = entry

        expect(recorded['http']['responseBody']['status']).to eq 'present'
        expect(recorded.dig('http', 'responseBody', 'value', 'props', 'blob').length).to eq 300_000
        expect(recorded['propValues']['blob'].length).to eq 300_000
        expect(recorded['props']).to include('blob')
      end

      it 'omits a request body over the size limit' do
        post devtools_create_path, params: { blob: 'x' * 300_000 }.to_json,
                                   headers: { 'X-Inertia' => true, 'CONTENT_TYPE' => 'application/json' }

        expect(entry['http']['requestBody']).to eq('status' => 'omitted', 'reason' => 'too-large')
      end

      it 'expires the entries of other tabs when a new tab starts' do
        get devtools_props_path, headers: { 'X-Inertia-Devtools-Tab' => 'old-tab' }
        stale = 25.hours.ago.to_time
        Dir.glob(File.join(storage_path, 'old-tab', '*.json')).each { |file| File.utime(stale, stale, file) }

        get devtools_props_path, headers: { 'X-Inertia-Devtools-Tab' => 'new-tab' }

        expect(entries.map { |meta| meta['tabUuid'] }).to eq ['new-tab']
      end
    end

    describe 'exceptions' do
      it 'records nothing for an exception no response comes back for' do
        expect { get devtools_boom_path }.to raise_error(RuntimeError, 'devtools boom')

        expect(entries).to be_empty
      end

      it 'stamps the response rendered by Rails exception handling' do
        env_config = Rails.application.env_config
        original = env_config['action_dispatch.show_exceptions']
        env_config['action_dispatch.show_exceptions'] = Rails.version < '7.1' ? true : :all

        get devtools_boom_path

        id = response.headers['x-inertia-devtools-id']

        expect(response).to have_http_status(:internal_server_error)
        expect(id).to match(InertiaRails::Devtools::EntryStore::ID_FORMAT)
        expect(InertiaRails::Devtools.store.read(id)).to include(
          '__meta' => include('status' => 500, 'requestType' => 'http'),
          'http' => include('responseBody' => { 'status' => 'omitted', 'reason' => 'non-inertia-response' })
        )
      ensure
        env_config['action_dispatch.show_exceptions'] = original
      end
    end

    it 'emits an empty route object when no Rails route handled the response' do
      in_development
      app = ->(_env) { [401, { 'content-type' => 'text/plain' }, ['blocked']] }
      env = Rack::MockRequest.env_for('/blocked')
      _status, headers, _body = InertiaRails::Devtools::Middleware.new(app).call(env)

      id = headers['x-inertia-devtools-id']
      expect(InertiaRails::Devtools.store.read(id)['route']).to eq(
        'name' => nil, 'uri' => '', 'action' => nil
      )
    end

    it 'records a path that only starts like the read API' do
      in_development
      app = ->(_env) { [404, { 'content-type' => 'text/plain' }, ['missing']] }
      env = Rack::MockRequest.env_for('/_inertia/devtoolsx')
      _status, headers, _body = InertiaRails::Devtools::Middleware.new(app).call(env)

      expect(headers).to have_key('x-inertia-devtools-id')
    end

    it 'skips a response whose headers a Rack app froze' do
      in_development
      app = ->(_env) { [200, { 'content-type' => 'text/plain' }.freeze, ['ok']] }
      _status, headers, _body = InertiaRails::Devtools::Middleware.new(app).call(Rack::MockRequest.env_for('/frozen'))

      expect(headers).not_to have_key('x-inertia-devtools-id')
      expect(entries).to be_empty
    end

    it 'never breaks the response when recording fails' do
      allow(InertiaRails::Devtools::EntryBuilder).to receive(:new).and_raise('boom')

      get devtools_props_path

      expect(response.status).to eq 200
    end
  end
end
