# frozen_string_literal: true

RSpec.describe 'errors shared automatically', type: :request do
  context 'always_include_errors_hash configuration' do
    let(:server_version) { 1.0 }
    let(:headers) { { 'X-Inertia' => true } }

    after { InertiaRails.configure { |c| c.always_include_errors_hash = nil } }

    context 'when always_include_errors_hash is true' do
      before { InertiaRails.configure { |c| c.always_include_errors_hash = true } }

      it 'includes empty errors hash when no errors present' do
        get empty_test_path, headers: headers
        expect(response.body).to include({ errors: {} }.to_json)
      end

      it 'still includes actual errors when they exist' do
        post redirect_with_inertia_errors_path, headers: headers
        get response.headers['Location'], headers: headers
        expect(response.body).to include({ errors: { uh: 'oh' } }.to_json)
      end
    end

    context 'when always_include_errors_hash is false' do
      before { InertiaRails.configure { |c| c.always_include_errors_hash = false } }

      it 'does not include errors hash when no errors present' do
        get empty_test_path, headers: headers
        expect(response.body).not_to include('"errors"')
      end

      it 'still includes actual errors when they exist' do
        post redirect_with_inertia_errors_path, headers: headers
        get response.headers['Location'], headers: headers
        expect(response.body).to include({ errors: { uh: 'oh' } }.to_json)
      end
    end

    context 'when always_include_errors_hash is nil (default)' do
      before { InertiaRails.configure { |c| c.always_include_errors_hash = nil } }

      it 'shows deprecation warning and does not include empty errors hash' do
        expect { get empty_test_path, headers: headers }
          .to output(/To comply with the Inertia protocol/).to_stderr
        expect(response.body).not_to include('"errors"')
      end

      it 'still includes actual errors when they exist' do
        post redirect_with_inertia_errors_path, headers: headers
        get response.headers['Location'], headers: headers
        expect(response.body).to include({ errors: { uh: 'oh' } }.to_json)
      end
    end
  end

  context 'rendering errors across redirects' do
    let(:server_version) { 1.0 }
    let(:headers) { { 'X-Inertia' => true, 'X-Inertia-Version' => server_version } }

    before { InertiaRails.configure { |c| c.version = server_version } }
    after { InertiaRails.configure { |c| c.version = nil } }

    it 'automatically renders errors in inertia' do
      post redirect_with_inertia_errors_path, headers: headers
      expect(response.headers['Location']).to eq(empty_test_url)
      expect(session[:inertia_errors]).to include({ uh: 'oh' })

      # Follow the redirect
      get response.headers['Location'], headers: headers
      expect(response.body).to include({ errors: { uh: 'oh' } }.to_json)
      expect(session[:inertia_errors]).not_to be
    end

    it 'copies flattened dot-notated keys for nested errors' do
      post redirect_with_nested_inertia_errors_path, headers: headers

      expect(session[:inertia_errors]).to include(user: { name: 'is required', email: 'is invalid' })
      expect(session[:inertia_errors]).to include('user.name' => 'is required', 'user.email' => 'is invalid')

      get response.headers['Location'], headers: headers
      body = JSON.parse(response.body)
      errors = body['props']['errors']
      expect(errors['user']).to eq({ 'name' => 'is required', 'email' => 'is invalid' })
      expect(errors['user.name']).to eq('is required')
      expect(errors['user.email']).to eq('is invalid')
    end

    it 'does not add duplicate keys for flat errors' do
      post redirect_with_inertia_errors_path, headers: headers

      errors = session[:inertia_errors]
      expect(errors.keys).to eq([:uh])
    end

    it 'accepts a non-hash error object' do
      expect { post redirect_with_non_hash_inertia_errors_path, headers: headers }
        .to output(/Object passed to `inertia: { errors: ... }` must respond to `to_hash`/).to_stderr
      expect(response.headers['Location']).to eq(empty_test_url)
      expect(session[:inertia_errors]).to eq('uh oh')

      # Follow the redirect
      get response.headers['Location'], headers: headers
      expect(response.body).to include({ errors: 'uh oh' }.to_json)
      expect(session[:inertia_errors]).not_to be
    end

    it 'keeps errors around when the post has a stale version' do
      post redirect_with_inertia_errors_path, headers: headers
      expect(response.headers['Location']).to eq(empty_test_url)
      expect(session[:inertia_errors]).to include({ uh: 'oh' })

      # Simulate that the POST was using a stale version
      get empty_test_path, headers: headers.merge({ 'X-Inertia-Version' => 'stale' })
      expect(response.status).to eq(409)
      # Inertia errors are _not_ deleted
      expect(session[:inertia_errors]).to include({ uh: 'oh' }.as_json)

      # Simulate the page refresh that Inertia triggers in response to a 409
      get empty_test_path
      expect(response.body).to include(CGI.escape_html({ errors: { uh: 'oh' } }.to_json))
      expect(session[:inertia_errors]).not_to be
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

      it 'keeps errors when partial inertia request redirects' do
        post redirect_with_inertia_errors_path, headers: headers
        expect(response.headers['Location']).to eq(empty_test_url)
        expect(session[:inertia_errors]).to include({ uh: 'oh' })

        # Follow the redirect
        get response.headers['Location'], headers: headers
        expect(response.body).to include({ errors: { uh: 'oh' } }.to_json)
        expect(session[:inertia_errors]).not_to be
      end
    end
  end
end
