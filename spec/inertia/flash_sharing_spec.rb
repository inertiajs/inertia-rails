# frozen_string_literal: true

RSpec.describe 'flash data shared via redirect', type: :request do
  let(:server_version) { 1.0 }
  let(:headers) { { 'X-Inertia' => true, 'X-Inertia-Version' => server_version } }

  before { InertiaRails.configure { |c| c.version = server_version } }
  after { InertiaRails.configure { |c| c.version = nil } }

  context 'rendering flash across redirects' do
    it 'stores flash for next request on redirect' do
      post redirect_with_inertia_flash_path, headers: headers
      expect(response.headers['Location']).to eq(empty_test_url)
      expect(flash[:inertia]).to eq({ toast: 'Hello!' })
    end

    it 'includes flash in response after redirect' do
      post redirect_with_inertia_flash_path, headers: headers
      get response.headers['Location'], headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'toast' => 'Hello!' })
    end

    it 'clears flash after rendering' do
      post redirect_with_inertia_flash_path, headers: headers
      get response.headers['Location'], headers: headers
      # Flash was consumed during render, verify it doesn't appear in next response
      get empty_test_path, headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed).not_to have_key('flash')
    end

    it 'does not include flash key when no flash data present' do
      get empty_test_path, headers: headers
      parsed = JSON.parse(response.body)
      expect(parsed).not_to have_key('flash')
    end

    it 'supports flash.inertia[:key] = value syntax' do
      get render_with_inertia_flash_method_path, headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'foo' => 'bar', 'baz' => 'qux' })
    end

    it 'supports flash.now.inertia for current request only' do
      get render_with_inertia_flash_now_path, headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'temporary' => 'current request only' })
    end

    it 'does not persist flash.now.inertia to next request' do
      get render_with_inertia_flash_now_path, headers: headers
      get empty_test_path, headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed).not_to have_key('flash')
    end

    it 'persists flash.now.inertia when flash.keep(:inertia) is called' do
      post redirect_with_kept_inertia_flash_now_path, headers: headers
      get response.headers['Location'], headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'kept' => 'this was .now but kept' })
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
    it 'preserves flash from last redirect only (standard Rails behavior)' do
      post double_redirect_with_flash_path, headers: headers
      expect(flash[:inertia]).to eq({ 'first' => 'first flash' })

      # Follow first redirect - first flash is consumed, second flash is set
      get response.headers['Location'], headers: headers
      expect(response).to have_http_status(:redirect)

      # Follow second redirect - only the last flash survives (Rails discards after read)
      get response.headers['Location'], headers: headers
      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'toast' => 'Hello!' })
    end
  end

  context 'flash with stale version request' do
    it 'returns 409 with X-Inertia-Location when version is stale' do
      post redirect_with_inertia_flash_path, headers: headers
      expect(flash[:inertia]).to eq({ toast: 'Hello!' })

      # Simulate stale version request - returns 409 with location header
      get empty_test_path, headers: headers.merge({ 'X-Inertia-Version' => 'stale' })
      expect(response.status).to eq(409)
      expect(response.headers['X-Inertia-Location']).to eq("http://www.example.com#{empty_test_path}")
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
      expect(flash[:inertia]).to eq({ toast: 'Hello!' })

      get response.headers['Location'], headers: headers
      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'toast' => 'Hello!' })
    end
  end

  context 'Rails flash integration' do
    it 'supports flash: { inertia: {...} } pattern' do
      post redirect_with_flash_inertia_hash_path, headers: headers
      get response.headers['Location'], headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'toast' => 'Rails style!' })
    end

    it 'includes notice from Rails flash' do
      post redirect_with_rails_notice_path, headers: headers
      get response.headers['Location'], headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'notice' => 'Created!' })
    end

    it 'includes alert from Rails flash' do
      post redirect_with_rails_alert_path, headers: headers
      get response.headers['Location'], headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'alert' => 'Something went wrong' })
    end

    it 'merges Rails flash with inertia namespace' do
      post redirect_with_mixed_flash_path, headers: headers
      get response.headers['Location'], headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({
                                      'notice' => 'Notice!',
                                      'custom' => 'custom value',
                                    })
    end

    it 'excludes non-allowlisted keys' do
      post redirect_with_non_allowlisted_key_path, headers: headers
      get response.headers['Location'], headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'notice' => 'Safe notice' })
      expect(parsed['flash']).not_to have_key('secret_token')
    end
  end

  context 'flash_keys configuration' do
    after { InertiaRails.configure { |c| c.flash_keys = %i[notice alert error warning info success] } }

    it 'respects custom flash_keys configuration' do
      InertiaRails.configure { |c| c.flash_keys = %i[notice secret_token] }

      post redirect_with_non_allowlisted_key_path, headers: headers
      get response.headers['Location'], headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed['flash']).to eq({ 'notice' => 'Safe notice', 'secret_token' => 'super_secret' })
    end

    it 'disables Rails flash when flash_keys is nil' do
      InertiaRails.configure { |c| c.flash_keys = nil }

      post redirect_with_rails_notice_path, headers: headers
      get response.headers['Location'], headers: headers

      parsed = JSON.parse(response.body)
      expect(parsed).not_to have_key('flash')
    end
  end
end
