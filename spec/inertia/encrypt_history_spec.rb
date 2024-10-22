RSpec.describe 'Inertia encrypt history', type: :request do
  let(:headers) { {'X-Inertia' => true} }

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
end
