RSpec.describe 'errors shared automatically', type: :request do
  context 'rendering errors across redirects' do
    let(:server_version){ 1.0 }
    let(:headers){ { 'X-Inertia' => true, 'X-Inertia-Version' => server_version } }

    before { InertiaRails.configure{|c| c.version = server_version} }
    after { InertiaRails.configure{|c| c.version = nil } }

    it 'automatically renders errors in inertia' do
      post redirect_with_inertia_errors_path, headers: headers
      expect(response.headers['Location']).to eq(empty_test_url)
      expect(session[:inertia_errors]).to include({ uh: 'oh' })

      # Follow the redirect
      get response.headers['Location'], headers: headers
      expect(response.body).to include({ errors: { uh: 'oh' } }.to_json)
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
      expect(response.body).to include(CGI::escape_html({ errors: { uh: 'oh' } }.to_json))
      expect(session[:inertia_errors]).not_to be
    end
  end
end
