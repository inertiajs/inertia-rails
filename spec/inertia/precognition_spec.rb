# frozen_string_literal: true

RSpec.describe 'Precognition', type: :request do
  let(:precognition_headers) { { 'Precognition' => 'true' } }
  let(:valid_user_params) { { user: { name: 'Jane Doe', email: 'jane@example.com' } } }
  let(:blank_user_params) { { user: { name: '', email: '' } } }

  def validate_only_headers(*fields)
    precognition_headers.merge('Precognition-Validate-Only' => fields.join(', '))
  end

  describe 'precognition_request?' do
    it 'returns true when Precognition header is present' do
      post precognition_basic_path, params: valid_user_params, headers: precognition_headers

      expect(response).to have_http_status(:no_content)
    end

    it 'returns false when Precognition header is absent' do
      post precognition_without_path

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ 'message' => 'hello' })
    end
  end

  describe 'precognition!' do
    context 'when validation passes' do
      before do
        post precognition_basic_path, params: valid_user_params, headers: precognition_headers
      end

      it 'returns 204 No Content' do
        expect(response).to have_http_status(:no_content)
      end

      it 'sets Precognition header in response' do
        expect(response.headers['Precognition']).to eq('true')
      end

      it 'sets Precognition-Success header in response' do
        expect(response.headers['Precognition-Success']).to eq('true')
      end

      it 'returns empty body' do
        expect(response.body).to be_empty
      end
    end

    context 'when validation fails' do
      before do
        post precognition_basic_path, params: blank_user_params, headers: precognition_headers
      end

      it 'returns 422 Unprocessable Entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'sets Precognition header in response' do
        expect(response.headers['Precognition']).to eq('true')
      end

      it 'does not set Precognition-Success header' do
        expect(response.headers['Precognition-Success']).to be_nil
      end

      it 'returns errors as JSON' do
        body = JSON.parse(response.body)
        expect(body['errors']).to include('name', 'email')
        expect(body['errors']['name']).to include("can't be blank")
        expect(body['errors']['email']).to include("can't be blank")
      end
    end

    it 'returns format validation errors' do
      post precognition_basic_path,
           params: { user: { name: 'Jane Doe', email: 'not-an-email' } },
           headers: precognition_headers

      body = JSON.parse(response.body)
      expect(body['errors']).to include('email')
      expect(body['errors']['email']).to include('is invalid')
    end

    context 'with Precognition-Validate-Only header' do
      it 'returns only specified field errors' do
        post precognition_basic_path, params: blank_user_params, headers: validate_only_headers('name')

        body = JSON.parse(response.body)
        expect(body['errors'].keys).to eq(['name'])
      end

      it 'returns multiple specified field errors' do
        post precognition_basic_path,
             params: { user: { name: '', email: 'not-an-email' } },
             headers: validate_only_headers('name', 'email')

        body = JSON.parse(response.body)
        expect(body['errors'].keys).to match_array(%w[name email])
      end

      it 'returns 204 when specified fields are valid even if others are not' do
        post precognition_basic_path,
             params: { user: { name: 'Jane Doe', email: '' } },
             headers: validate_only_headers('name')

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when not a precognition request' do
      it 'does not intercept the request' do
        post precognition_basic_path, params: valid_user_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'success' => true })
      end

      it 'allows action to handle invalid data' do
        post precognition_basic_path, params: blank_user_params

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with before_action pattern' do
      it 'works with validator built in before_action' do
        post precognition_with_before_action_path, params: blank_user_params, headers: precognition_headers

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['errors']).to include('name', 'email')
      end

      it 'returns 204 when valid' do
        post precognition_with_before_action_path, params: valid_user_params, headers: precognition_headers

        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe 'precognition (non-bang)' do
    context 'when validation passes' do
      it 'returns 204 No Content with success headers' do
        post precognition_non_bang_path, params: valid_user_params, headers: precognition_headers

        expect(response).to have_http_status(:no_content)
        expect(response.headers['Precognition']).to eq('true')
        expect(response.headers['Precognition-Success']).to eq('true')
      end
    end

    context 'when validation fails' do
      it 'returns 422 with errors' do
        post precognition_non_bang_path, params: blank_user_params, headers: precognition_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.headers['Precognition']).to eq('true')
        body = JSON.parse(response.body)
        expect(body['errors']).to include('name', 'email')
      end
    end

    context 'when not a precognition request' do
      it 'does not intercept the request' do
        post precognition_non_bang_path, params: valid_user_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'success' => true })
      end
    end
  end

  describe 'InertiaRails.precognition! (module-level)' do
    it 'returns 422 with errors when invalid' do
      post precognition_with_module_level_path, params: blank_user_params, headers: precognition_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.headers['Precognition']).to eq('true')
      body = JSON.parse(response.body)
      expect(body['errors']).to include('name', 'email')
    end

    it 'returns 204 when valid' do
      post precognition_with_module_level_path, params: valid_user_params, headers: precognition_headers

      expect(response).to have_http_status(:no_content)
      expect(response.headers['Precognition-Success']).to eq('true')
    end

    it 'does not intercept normal requests' do
      post precognition_with_module_level_path, params: valid_user_params

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ 'success' => true })
    end
  end

  describe 'custom validators' do
    it 'works with validators that return a hash' do
      post precognition_with_custom_validator_path, params: blank_user_params, headers: precognition_headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['errors']['name']).to include('is required')
    end

    it 'returns 204 when custom validator passes' do
      post precognition_with_custom_validator_path, params: valid_user_params, headers: precognition_headers

      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'string-keyed error hashes' do
    it 'returns errors when hash has string keys' do
      post precognition_with_string_keyed_errors_path, params: blank_user_params, headers: precognition_headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['errors']['name']).to include('is required')
    end

    context 'with Precognition-Validate-Only header' do
      it 'filters correctly with string-keyed errors' do
        post precognition_with_string_keyed_errors_path,
             params: blank_user_params,
             headers: validate_only_headers('name')

        body = JSON.parse(response.body)
        expect(body['errors'].keys).to eq(['name'])
      end

      it 'returns 204 when filtered string-keyed fields are valid' do
        post precognition_with_string_keyed_errors_path,
             params: { user: { name: 'Jane Doe', email: '' } },
             headers: validate_only_headers('name')

        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe 'request helpers' do
    it 'inertia_precognitive? returns true for precognition requests' do
      post precognition_basic_path, params: valid_user_params, headers: precognition_headers

      expect(response).to have_http_status(:no_content)
    end

    it 'inertia_precognitive? returns false for normal requests' do
      post precognition_without_path

      expect(response).to have_http_status(:ok)
    end
  end
end
