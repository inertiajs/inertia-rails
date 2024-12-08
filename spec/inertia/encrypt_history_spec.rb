# frozen_string_literal: true

RSpec.describe 'Inertia encrypt history', type: :request do
  let(:headers) { { 'X-Inertia' => true } }

  context 'with default config' do
    it 'returns encryptHistory false' do
      get encrypt_history_default_config_path, headers: headers

      expect(response.parsed_body['encryptHistory']).to eq(false)
      expect(response.parsed_body['clearHistory']).to eq(false)
    end
  end

  context 'with encrypt history config' do
    it 'returns encryptHistory true' do
      get encrypt_history_encrypt_history_path, headers: headers

      expect(response.parsed_body['encryptHistory']).to eq(true)
      expect(response.parsed_body['clearHistory']).to eq(false)
    end
  end

  context 'with override config' do
    it 'returns encryptHistory false' do
      get encrypt_history_override_config_path, headers: headers

      expect(response.parsed_body['encryptHistory']).to eq(false)
      expect(response.parsed_body['clearHistory']).to eq(false)
    end
  end

  context 'with clear history' do
    it 'returns clearHistory true' do
      get encrypt_history_clear_history_path, headers: headers

      expect(response.parsed_body['clearHistory']).to eq(true)
    end
  end

  context 'with clear history on redirect' do
    it 'returns clearHistory true after the redirect' do
      post encrypt_history_clear_history_after_redirect_path, headers: headers

      expect(response.headers['Location']).to eq(empty_test_url)
      expect(session[:inertia_clear_history]).to eq(true)

      follow_redirect!
      expect(response.body).to include('&quot;clearHistory&quot;:true')

      get empty_test_path, headers: headers
      expect(response.parsed_body['clearHistory']).to eq(false)
    end
  end
end
