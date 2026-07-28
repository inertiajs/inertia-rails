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

    it 'hides the read API' do
      get '/_inertia/devtools/entries'

      expect(response.status).to eq 404
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

      # Deferred and optional props are skipped before resolution on a first
      # load, so they only show up on the request that actually delivers them.
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
    end

    describe 'redirects' do
      it 'records the redirect target' do
        post devtools_create_path, headers: { 'X-Inertia' => true }

        expect(entries.first['status']).to eq 302
        expect(entry['__meta']['redirectLocation']).to end_with('/devtools_props')
      end

      it 'omits a non-Inertia write body' do
        post devtools_create_path, params: { password: 'hunter2' }

        expect(entry['http']['requestBody']).to eq('status' => 'omitted', 'reason' => 'non-inertia-request')
      end
    end

    describe 'the read API' do
      before { get devtools_props_path }

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
    end

    it 'never breaks the response when recording fails' do
      allow(InertiaRails::Devtools::EntryBuilder).to receive(:new).and_raise('boom')

      get devtools_props_path

      expect(response.status).to eq 200
    end
  end
end
