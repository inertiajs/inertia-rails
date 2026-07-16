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

  context 'a redirect to an external (cross-origin) url' do
    context 'with an inertia request' do
      it 'converts the redirect to a conflict response with the location header' do
        get external_redirect_test_path, headers: { 'X-Inertia' => true }

        expect(response.status).to eq 409
        expect(response.headers['X-Inertia-Location']).to eq 'http://external-website.com/some_path'
        expect(response.headers['Location']).to be_nil
        expect(response.headers['Content-Type']).to be_nil
        expect(response.body).to be_empty
      end

      it 'converts a route-level redirect' do
        get route_level_redirect_test_path, headers: { 'X-Inertia' => true }

        expect(response.status).to eq 409
        expect(response.headers['X-Inertia-Location']).to eq 'http://external-website.com/some_path'
      end

      it 'preserves other response headers such as Set-Cookie' do
        get external_redirect_with_cookie_test_path, headers: { 'X-Inertia' => true }

        expect(response.status).to eq 409
        expect(response.headers['X-Inertia-Location']).to eq 'http://external-website.com/some_path'
        expect(cookies['external_cookie']).to eq 'hello'
      end

      %w[put patch delete].each do |method|
        it "converts a #{method.upcase} redirect to 409 instead of 303" do
          public_send method, external_redirect_test_path, headers: { 'X-Inertia' => true }

          expect(response.status).to eq 409
          expect(response.headers['X-Inertia-Location']).to eq 'http://external-website.com/some_path'
        end
      end

      it 'does not keep inertia session options, matching inertia_location semantics' do
        post external_redirect_with_inertia_errors_test_path, headers: { 'X-Inertia' => true }

        expect(response.status).to eq 409
        expect(session[:inertia_errors]).to be_nil
      end

      it 'does not convert a same-origin redirect' do
        get same_origin_redirect_test_path, headers: { 'X-Inertia' => true }

        expect(response.status).to eq 302
        expect(response.headers['Location']).to eq empty_test_url
      end

      it 'does not convert a method-preserving (307) redirect' do
        get location_header_test_path(url: 'http://external-website.com/some_path', status: 307),
            headers: { 'X-Inertia' => true }

        expect(response.status).to eq 307
        expect(response.headers['Location']).to eq 'http://external-website.com/some_path'
        expect(response.headers['X-Inertia-Location']).to be_nil
      end

      context 'when the asset version is stale' do
        with_inertia_config version: '1.0'

        it 'prefers the external redirect over a forced refresh' do
          get external_redirect_test_path, headers: { 'X-Inertia' => true, 'X-Inertia-Version' => 'stale' }

          expect(response.status).to eq 409
          expect(response.headers['X-Inertia-Location']).to eq 'http://external-website.com/some_path'
        end
      end

      context 'when conversion is disabled' do
        with_inertia_config convert_external_redirects: false

        it 'does not convert the redirect' do
          get external_redirect_test_path, headers: { 'X-Inertia' => true }

          expect(response.status).to eq 302
          expect(response.headers['Location']).to eq 'http://external-website.com/some_path'
        end
      end

      context 'when conversion is disabled for a specific controller' do
        it 'does not convert the redirect' do
          get opt_out_external_redirect_test_path, headers: { 'X-Inertia' => true }

          expect(response.status).to eq 302
          expect(response.headers['Location']).to eq 'http://external-website.com/some_path'
        end
      end
    end

    context 'with a non-inertia request' do
      it 'does not convert the redirect' do
        get external_redirect_test_path

        expect(response.status).to eq 302
        expect(response.headers['Location']).to eq 'http://external-website.com/some_path'
      end
    end
  end

  context 'a same-origin redirect marked with inertia: { full_page: true }' do
    context 'with an inertia request' do
      it 'converts the redirect to a conflict response with the location header' do
        get full_page_redirect_test_path, headers: { 'X-Inertia' => true }

        expect(response.status).to eq 409
        expect(response.headers['X-Inertia-Location']).to eq empty_test_url
        expect(response.headers['Location']).to be_nil
      end

      context 'when automatic conversion is disabled' do
        with_inertia_config convert_external_redirects: false

        it 'still converts the redirect' do
          get full_page_redirect_test_path, headers: { 'X-Inertia' => true }

          expect(response.status).to eq 409
          expect(response.headers['X-Inertia-Location']).to eq empty_test_url
        end
      end
    end

    context 'with a non-inertia request' do
      it 'redirects normally' do
        get full_page_redirect_test_path

        expect(response.status).to eq 302
        expect(response.headers['Location']).to eq empty_test_url
      end
    end

    it 'raises for a method-preserving redirect status' do
      expect do
        get invalid_full_page_redirect_test_path, headers: { 'X-Inertia' => true }
      end.to raise_error(ArgumentError, /full_page: true/)
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
