# frozen_string_literal: true

RSpec.describe 'flash data shared via redirect', type: :request do
  let(:server_version) { 1.0 }
  let(:headers) { { 'X-Inertia' => true, 'X-Inertia-Version' => server_version } }

  before { InertiaRails.configure { |c| c.version = server_version } }
  after { InertiaRails.configure { |c| c.version = nil } }

  context 'rendering flash across redirects' do
    it 'stores flash in session on redirect' do
      post redirect_with_inertia_flash_path, headers: headers
      expect(response.headers['Location']).to eq(empty_test_url)
      expect(session[:inertia_flash_data]).to include({ toast: 'Hello!' })
    end

    it 'includes flash in response after redirect' do
      post redirect_with_inertia_flash_path, headers: headers
      get response.headers['Location'], headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'toast' => 'Hello!' })
    end

    it 'clears flash from session after rendering' do
      post redirect_with_inertia_flash_path, headers: headers
      get response.headers['Location'], headers: headers

      expect(session[:inertia_flash_data]).to be_nil
    end

    it 'raises an error for non-hash flash value' do
      expect do
        post redirect_with_non_hash_inertia_flash_path, headers: headers
      end.to raise_error(ArgumentError, /must be a Hash/)
    end

    it 'does not include flash key when no flash data present' do
      get empty_test_path, headers: headers
      parsed = JSON.parse(response.body)
      expect(parsed).not_to have_key('flash')
    end

    it 'supports inertia_flash[:key] = value syntax' do
      get render_with_inertia_flash_method_path, headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'foo' => 'bar', 'baz' => 'qux' })
      expect(session[:inertia_flash_data]).to be_nil
    end
  end

  context 'flash with errors' do
    it 'includes both flash and errors in response' do
      post redirect_with_inertia_flash_and_errors_path, headers: headers
      get response.headers['Location'], headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'toast' => 'Saved!' })
      expect(parsed['props']['errors']).to eq({ 'name' => 'is required' })
    end
  end

  context 'flash persistence across multiple redirects' do
    it 'accumulates flash data across redirects' do
      post double_redirect_with_flash_path, headers: headers
      expect(session[:inertia_flash_data]).to include({ first: 'first flash' })

      # Follow first redirect
      get response.headers['Location'], headers: headers
      expect(response).to have_http_status(:redirect)
      expect(session[:inertia_flash_data].stringify_keys).to include('first' => 'first flash', 'toast' => 'Hello!')

      # Follow second redirect
      get response.headers['Location'], headers: headers
      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to include('first' => 'first flash', 'toast' => 'Hello!')
      expect(session[:inertia_flash_data]).to be_nil
    end
  end

  context 'flash with stale version request' do
    it 'keeps flash data when version is stale' do
      post redirect_with_inertia_flash_path, headers: headers
      expect(session[:inertia_flash_data]).to include({ toast: 'Hello!' })

      # Simulate stale version request
      get empty_test_path, headers: headers.merge({ 'X-Inertia-Version' => 'stale' })
      expect(response.status).to eq(409)
      expect(session[:inertia_flash_data]).to include({ 'toast' => 'Hello!' })

      # Simulate page refresh after 409
      get empty_test_path
      expect(response.body).to include(CGI.escape_html('"flash":{"toast":"Hello!"}'))
      expect(session[:inertia_flash_data]).to be_nil
    end
  end

  context 'flash is at page level, not in props' do
    it 'places flash data at page level, separate from props' do
      post redirect_with_inertia_flash_path, headers: headers
      get response.headers['Location'], headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed).to have_key('flash')
      expect(parsed['props']).not_to have_key('flash')
    end
  end

  context 'with partial update' do
    let(:headers) do
      {
        'X-Inertia' => true,
        'X-Inertia-Version' => server_version,
        'X-Inertia-Partial-Component' => 'EmptyTestComponent',
        'X-Inertia-Partial-Data' => 'foo',
      }
    end

    it 'keeps flash when partial inertia request redirects' do
      post redirect_with_inertia_flash_path, headers: headers
      expect(response.headers['Location']).to eq(empty_test_url)
      expect(session[:inertia_flash_data]).to include({ toast: 'Hello!' })

      get response.headers['Location'], headers: headers
      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'toast' => 'Hello!' })
      expect(session[:inertia_flash_data]).to be_nil
    end
  end
end
