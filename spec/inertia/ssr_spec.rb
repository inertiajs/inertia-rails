# frozen_string_literal: true

RSpec.describe 'inertia ssr', type: :request do
  let(:page_json) do
    {
      component: 'TestComponent',
      props: { name: 'Brandon', sport: 'hockey' },
      url: props_path,
      version: '1.0',
      encryptHistory: false,
      clearHistory: false,
    }.to_json
  end

  # rubocop:disable Layout/LineLength
  let(:client_side_html) do
    '<div id="app" data-page="{&quot;component&quot;:&quot;TestComponent&quot;,&quot;props&quot;:{&quot;name&quot;:&quot;Brandon&quot;,&quot;sport&quot;:&quot;hockey&quot;},&quot;url&quot;:&quot;/props&quot;,&quot;version&quot;:&quot;1.0&quot;,&quot;encryptHistory&quot;:false,&quot;clearHistory&quot;:false}"></div>'
  end
  # rubocop:enable Layout/LineLength

  def stub_ssr_response(url:, body:, status: 200)
    http_response = instance_double(Net::HTTPOK, body: body.to_json, code: status.to_s)
    allow(http_response).to receive(:is_a?) do |klass|
      status.between?(200, 299) ? [Net::HTTPSuccess, Net::HTTPOK].include?(klass) : false
    end
    allow(Net::HTTP).to receive(:post)
      .with(URI(url), page_json, 'Content-Type' => 'application/json')
      .and_return(http_response)
  end

  context 'ssr is enabled' do
    with_inertia_config ssr_enabled: true, ssr_url: 'http://localhost:13714', version: '1.0'

    context 'with a successful ssr response' do
      before do
        stub_ssr_response(
          url: 'http://localhost:13714/render',
          body: { body: '<div>Test works</div>', head: ['<title>Title works</title>'] }
        )
      end

      it 'returns the result of the ssr call' do
        get props_path

        expect(response.body).to include('<title>Title works</title>')
        expect(response.body).to include('<div>Test works</div>')
        expect(response.headers['Content-Type']).to eq 'text/html; charset=utf-8'
      end

      it 'allows inertia to take over when inertia headers are passed' do
        get props_path, headers: { 'X-Inertia' => true, 'X-Inertia-Version' => '1.0' }

        expect(response.headers['Vary']).to eq 'X-Inertia'
        expect(response.headers['Content-Type']).to eq 'application/json; charset=utf-8'
      end
    end

    context 'the ssr server fails with a connection error' do
      before do
        allow(Net::HTTP).to receive(:post).and_raise(Errno::ECONNREFUSED)
      end

      it 'falls back to client-side rendering' do
        get props_path
        expect(response.body).to include client_side_html
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/\[inertia-rails\] SSR render failed: .*refused/i)
        get props_path
      end

      it 'wraps the error as SSRError with connection type' do
        ssr_errors = []
        allow_any_instance_of(InertiaRails::Configuration).to receive(:on_ssr_error)
          .and_return(->(error, _page) { ssr_errors << error })

        get props_path

        expect(ssr_errors.first).to be_a(InertiaRails::SSRError)
        expect(ssr_errors.first.type).to eq 'connection'
      end
    end

    context 'the ssr server returns an error response' do
      before do
        stub_ssr_response(
          url: 'http://localhost:13714/render',
          status: 500,
          body: { error: 'window is not defined', type: 'browser-api', hint: 'Use a polyfill', browserApi: 'window' }
        )
      end

      it 'falls back to client-side rendering' do
        get props_path
        expect(response.body).to include client_side_html
      end

      it 'logs the structured error message' do
        expect(Rails.logger).to receive(:error).with('[inertia-rails] SSR render failed: window is not defined')
        get props_path
      end

      it 'parses structured error details' do
        ssr_errors = []
        allow_any_instance_of(InertiaRails::Configuration).to receive(:on_ssr_error)
          .and_return(->(error, _page) { ssr_errors << error })

        get props_path

        error = ssr_errors.first
        expect(error).to be_a(InertiaRails::SSRError)
        expect(error.message).to eq 'window is not defined'
        expect(error.type).to eq 'browser-api'
        expect(error.hint).to eq 'Use a polyfill'
        expect(error.browser_api).to eq 'window'
      end
    end

    context 'the ssr server returns invalid JSON' do
      before do
        http_response = instance_double(Net::HTTPOK, body: 'not json', code: '500')
        allow(http_response).to receive(:is_a?).and_return(false)
        allow(Net::HTTP).to receive(:post).and_return(http_response)
      end

      it 'falls back to client-side rendering' do
        get props_path
        expect(response.body).to include client_side_html
      end
    end

    context 'with on_ssr_error callback' do
      ssr_errors = []

      with_inertia_config(
        on_ssr_error: ->(error, page) { ssr_errors << [error, page] }
      )

      before do
        ssr_errors.clear
        allow(Net::HTTP).to receive(:post).and_raise(Errno::ECONNREFUSED)
      end

      it 'calls the callback with the error and page data' do
        get props_path

        expect(ssr_errors.length).to eq 1
        error, page = ssr_errors.first
        expect(error).to be_a(InertiaRails::SSRError)
        expect(error.message).to match(/refused/i)
        expect(page[:component]).to eq 'TestComponent'
      end
    end

    context 'with ssr_raise_on_error enabled' do
      with_inertia_config(ssr_raise_on_error: true)

      context 'when ssr server returns an error' do
        before do
          stub_ssr_response(
            url: 'http://localhost:13714/render',
            status: 500,
            body: {
              error: 'window is not defined',
              type: 'browser-api',
              hint: 'Use a polyfill',
              sourceLocation: 'app/Pages/Home.jsx:5',
            }
          )
        end

        it 'raises SSRError instead of falling back' do
          expect { get props_path }.to raise_error(InertiaRails::SSRError, 'window is not defined')
        end

        it 'includes error details in the exception' do
          get props_path
        rescue InertiaRails::SSRError => e
          expect(e.type).to eq 'browser-api'
          expect(e.hint).to eq 'Use a polyfill'
          expect(e.source_location).to eq 'app/Pages/Home.jsx:5'
        end
      end

      context 'when ssr server has a connection error' do
        before do
          allow(Net::HTTP).to receive(:post).and_raise(Errno::ECONNREFUSED)
        end

        it 'raises SSRError with connection type' do
          expect { get props_path }.to raise_error(InertiaRails::SSRError) do |error|
            expect(error.type).to eq 'connection'
          end
        end
      end
    end

    context 'with ssr_raise_on_error disabled' do
      with_inertia_config(ssr_raise_on_error: false)

      before do
        stub_ssr_response(
          url: 'http://localhost:13714/render',
          status: 500,
          body: { error: 'some error' }
        )
      end

      it 'does not raise, falls back to client-side rendering' do
        get props_path
        expect(response.body).to include client_side_html
      end
    end
  end

  context 'bundle detection' do
    with_inertia_config ssr_enabled: true, ssr_url: 'http://localhost:13714', version: '1.0'

    context 'when ssr_bundle is configured and bundle exists' do
      with_inertia_config(
        ssr_bundle: File.expand_path('../rails_helper.rb', __dir__) # a file that exists
      )

      before do
        stub_ssr_response(
          url: 'http://localhost:13714/render',
          body: { body: '<div>SSR</div>', head: ['<title>SSR</title>'] }
        )
      end

      it 'proceeds with SSR rendering' do
        get props_path
        expect(response.body).to include('<div>SSR</div>')
      end
    end

    context 'when ssr_bundle is configured and bundle does not exist' do
      with_inertia_config(ssr_bundle: '/nonexistent/path/ssr.js')

      it 'skips SSR and renders client-side' do
        get props_path
        expect(response.body).to include client_side_html
      end

      it 'does not make an HTTP request to the SSR server' do
        expect(Net::HTTP).not_to receive(:post)
        get props_path
      end
    end

    context 'when ssr_bundle is an array of paths and one exists' do
      with_inertia_config(
        ssr_bundle: ['/nonexistent/ssr.js', File.expand_path('../rails_helper.rb', __dir__)]
      )

      before do
        stub_ssr_response(
          url: 'http://localhost:13714/render',
          body: { body: '<div>SSR</div>', head: ['<title>SSR</title>'] }
        )
      end

      it 'proceeds with SSR rendering' do
        get props_path
        expect(response.body).to include('<div>SSR</div>')
      end
    end

    context 'when ssr_bundle is an array and none exist' do
      with_inertia_config(ssr_bundle: ['/nonexistent/ssr.js', '/nonexistent/app.mjs'])

      it 'skips SSR and renders client-side' do
        get props_path
        expect(response.body).to include client_side_html
      end
    end

    context 'when ssr_bundle is nil (default)' do
      with_inertia_config(ssr_bundle: nil)

      before do
        stub_ssr_response(
          url: 'http://localhost:13714/render',
          body: { body: '<div>SSR</div>', head: ['<title>SSR</title>'] }
        )
      end

      it 'skips bundle detection and proceeds with SSR' do
        get props_path
        expect(response.body).to include('<div>SSR</div>')
      end
    end

    context 'when vite dev server is running (bundle detection skipped)' do
      with_inertia_config(ssr_bundle: '/nonexistent/ssr.js')

      before do
        vite_instance = double(dev_server_running?: true)
        vite_config = double(protocol: 'http', host_with_port: 'localhost:5173')
        stub_const('ViteRuby', double(instance: vite_instance, config: vite_config))

        stub_ssr_response(
          url: 'http://localhost:5173/__inertia_ssr',
          body: { body: '<div>Hot SSR</div>', head: ['<title>Hot</title>'] }
        )
      end

      it 'skips bundle detection and uses vite dev server' do
        get props_path
        expect(response.body).to include('<div>Hot SSR</div>')
      end
    end
  end

  context 'vite dev server is running' do
    with_inertia_config ssr_enabled: true, ssr_url: 'http://localhost:13714', version: '1.0'

    let(:vite_config) { double(protocol: 'http', host_with_port: 'localhost:5173') }

    before do
      vite_instance = double(dev_server_running?: true)
      stub_const('ViteRuby', double(instance: vite_instance, config: vite_config))
    end

    context 'with a successful response' do
      before do
        stub_ssr_response(
          url: 'http://localhost:5173/__inertia_ssr',
          body: { body: '<div>Hot SSR</div>', head: ['<title>Hot Title</title>'] }
        )
      end

      it 'routes SSR requests to Vite dev server' do
        get props_path

        expect(response.body).to include('<title>Hot Title</title>')
        expect(response.body).to include('<div>Hot SSR</div>')
      end
    end

    context 'when vite ssr fails' do
      before do
        stub_ssr_response(
          url: 'http://localhost:5173/__inertia_ssr',
          status: 500,
          body: { error: 'document is not defined' }
        )
      end

      it 'falls back to client-side rendering' do
        get props_path
        expect(response.body).to include client_side_html
      end
    end
  end

  context 'vite dev server is not running' do
    with_inertia_config ssr_enabled: true, ssr_url: 'http://localhost:13714', version: '1.0'

    before do
      vite_instance = double(dev_server_running?: false)
      stub_const('ViteRuby', double(instance: vite_instance))
    end

    it 'uses the production SSR URL' do
      stub_ssr_response(
        url: 'http://localhost:13714/render',
        body: { body: '<div>Prod SSR</div>', head: ['<title>Prod</title>'] }
      )

      get props_path

      expect(response.body).to include('<div>Prod SSR</div>')
    end
  end

  context 'ViteRuby is not defined' do
    with_inertia_config ssr_enabled: true, ssr_url: 'http://localhost:13714', version: '1.0'

    it 'uses the production SSR URL' do
      stub_ssr_response(
        url: 'http://localhost:13714/render',
        body: { body: '<div>No Vite SSR</div>', head: ['<title>No Vite</title>'] }
      )

      get props_path

      expect(response.body).to include('<div>No Vite SSR</div>')
    end
  end

  describe InertiaRails::SSRError do
    it 'can be constructed from a response body' do
      error = InertiaRails::SSRError.from_response(
        'error' => 'window is not defined',
        'type' => 'browser-api',
        'hint' => 'Use a polyfill for window',
        'browserApi' => 'window',
        'stack' => "Error: window is not defined\n    at render (app.js:5)",
        'sourceLocation' => 'app/Pages/Home.jsx:5'
      )

      expect(error.message).to eq 'window is not defined'
      expect(error.type).to eq 'browser-api'
      expect(error.hint).to eq 'Use a polyfill for window'
      expect(error.browser_api).to eq 'window'
      expect(error.stack).to eq "Error: window is not defined\n    at render (app.js:5)"
      expect(error.source_location).to eq 'app/Pages/Home.jsx:5'
    end

    it 'can be constructed from an exception' do
      original = StandardError.new('Connection refused')
      original.set_backtrace(%w[line1 line2])

      error = InertiaRails::SSRError.from_exception(original)

      expect(error.message).to eq 'Connection refused'
      expect(error.type).to eq 'connection'
      expect(error.backtrace).to eq %w[line1 line2]
    end

    it 'defaults to Unknown SSR error when no error message in response' do
      error = InertiaRails::SSRError.from_response({})
      expect(error.message).to eq 'Unknown SSR error'
    end
  end
end
