# frozen_string_literal: true

RSpec.describe 'InertiaRails::Middleware', type: :request do
  context 'the version is set' do
    with_inertia_config version: '1.0'

    it 'tells the client with stale version to refresh' do
      get empty_test_path, headers: { 'X-Inertia' => true, 'X-Inertia-Version' => 'stale' }

      expect(response.status).to eq 409
      expect(response.headers['X-Inertia-Location']).to eq request.original_url
    end

    it 'returns page when version is up to date' do
      get empty_test_path, headers: { 'X-Inertia' => true, 'X-Inertia-Version' => '1.0' }

      expect(response.status).to eq 200
    end

    it 'returns response for non-inertia requests' do
      get empty_test_path, headers: { 'X-Inertia-Version' => 'stale' }

      expect(response.status).to eq 200
    end

    it 'returns 404 on unknown route' do
      expect do
        get '/unknown_route', headers: { 'X-Inertia' => true, 'X-Inertia-Version' => '1.0' }
      end.to raise_error(ActionController::RoutingError)
    end
  end

  context 'X-Inertia header on a non-Inertia controller' do
    with_inertia_config version: '1.0'

    it 'ignores the header on an ActionController::API endpoint' do
      get api_test_path
      baseline = response.status

      get api_test_path, headers: { 'X-Inertia' => true, 'X-Inertia-Version' => 'stale' }

      expect(response.status).to eq baseline
    end
  end

  context 'session loading guard' do
    it 'does not load the session when the request never accesses it' do
      get non_inertiafied_path

      # The middleware must not call session.delete (which triggers load_for_write!)
      # on requests that never touched the session — e.g. token-authenticated API endpoints.
      expect(request.session.loaded?).to be(false)
    end

    it 'still cleans up inertia session keys when the session was loaded during the request' do
      post redirect_with_inertia_errors_path
      expect(session[:inertia_errors]).to be_present

      # The follow-up GET causes Inertia to read inertia_errors from the session (loading it).
      # The middleware should then find session.loaded? == true and clean up the keys.
      get empty_test_path
      expect(request.session.loaded?).to be(true)
      expect(session[:inertia_errors]).to be_nil
    end
  end

  context 'inertia session options with explicit redirect statuses' do
    [303, 307, 308].each do |status|
      it "keeps inertia errors across a #{status} redirect" do
        post redirect_with_status_and_inertia_errors_path(status: status), headers: { 'X-Inertia' => true }

        expect(response.status).to eq status
        expect(session[:inertia_errors]).to be_present

        get response.headers['Location'], headers: { 'X-Inertia' => true }
        expect(response.body).to include({ errors: { uh: 'oh' } }.to_json)
      end
    end
  end

  context 'a redirect with an explicit status that must not be rewritten' do
    [303, 307, 308].each do |status|
      it "leaves an explicit #{status} as #{status}" do
        delete redirect_with_status_and_inertia_errors_path(status: status), headers: { 'X-Inertia' => true }

        expect(response.status).to eq status
      end
    end
  end

  context 'a redirect status was passed with an http method that preserves itself on 302 redirect' do
    subject { response.status }

    context 'PUT' do
      before { put redirect_test_path, headers: { 'X-Inertia' => true } }

      it { is_expected.to eq 303 }
    end

    context 'PATCH' do
      before { patch redirect_test_path, headers: { 'X-Inertia' => true } }

      it { is_expected.to eq 303 }
    end

    context 'DELETE' do
      before { delete redirect_test_path, headers: { 'X-Inertia' => true } }

      it { is_expected.to eq 303 }
    end

    it 'is thread safe' do
      # Capture route paths to fix flakiness
      redirect_path = redirect_test_path
      empty_path = empty_test_path

      delete_request_proc = -> { delete redirect_path, headers: { 'X-Inertia' => true } }
      get_request_proc = -> { get empty_path }

      statuses = Concurrent::Array.new

      threads = []

      100.times do
        threads << Thread.new { statuses << delete_request_proc.call }
        threads << Thread.new { get_request_proc.call }
      end

      threads.each(&:join)

      expect(statuses.uniq).to eq([303])
    end
  end
end
