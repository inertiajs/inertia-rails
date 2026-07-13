# frozen_string_literal: true

RSpec.describe 'Inertia::Request', type: :request do
  def set_cookie_header
    Array(response.headers['Set-Cookie']).join("\n")
  end

  describe 'it tests whether a call is an inertia call' do
    subject { response.status }
    before { get inertia_request_test_path, headers: headers }

    context 'it is an inertia call' do
      let(:headers) { { 'X-Inertia' => true } }

      it { is_expected.to eq 202 }
    end

    context 'it is not an inertia call' do
      let(:headers) { {} }

      it { is_expected.to eq 200 }
    end
  end

  describe 'it tests whether a call is a partial inertia call' do
    subject { response.status }
    before { get inertia_partial_request_test_path, headers: headers }

    context 'it is a partial inertia call' do
      let(:headers) do
        { 'X-Inertia' => true, 'X-Inertia-Partial-Component' => 'Component', 'X-Inertia-Partial-Data' => 'foo,bar,baz' }
      end

      it { is_expected.to eq 202 }
    end

    context 'it is not a partial inertia call' do
      let(:headers) { { 'X-Inertia' => true } }

      it { is_expected.to eq 200 }
    end
  end

  describe 'it tests error 404' do
    subject { response.status }
    before { get '/error_404', headers: headers }

    context 'it is a inertia call' do
      let(:headers) { { 'X-Inertia' => true } }

      it { is_expected.to eq 404 }
    end

    context 'it is not a inertia call' do
      let(:headers) { {} }

      it { is_expected.to eq 404 }
    end
  end

  describe 'it tests error 500' do
    subject { response.status }
    before { get '/error_500', headers: headers }

    context 'it is a inertia call' do
      let(:headers) { { 'X-Inertia' => true } }

      it { is_expected.to eq 500 }
    end

    context 'it is not a inertia call' do
      let(:headers) { {} }

      it { is_expected.to eq 500 }
    end
  end

  describe 'it tests media_type of the response' do
    subject { response.media_type }
    before { get content_type_test_path, headers: headers }

    context 'it is an inertia call' do
      let(:headers) { { 'X-Inertia' => true } }

      it { is_expected.to eq 'application/json' }
    end

    context 'it is not an inertia call' do
      let(:headers) { {} }

      it { is_expected.to eq 'text/html' }
    end

    context 'it is an XML request' do
      let(:headers) { { accept: 'application/xml' } }

      it { is_expected.to eq 'application/xml' }
    end
  end

  describe 'it tests redirecting with responders gem' do
    subject { response.status }
    before { post redirect_with_responders_path }

    it { is_expected.to eq 302 }
  end

  describe 'CSRF' do
    describe 'it sets the XSRF-TOKEN in the cookies' do
      subject { response.cookies }
      before do
        with_forgery_protection do
          get inertia_request_test_path, headers: headers
        end
      end

      context 'it is not an inertia call' do
        let(:headers) { {} }
        it { is_expected.to include('XSRF-TOKEN') }
      end

      context 'it is an inertia call' do
        let(:headers) { { 'X-Inertia' => true } }
        it { is_expected.to include('XSRF-TOKEN') }
      end
    end

    describe 'xsrf_cookie_refresh configuration' do
      it 'continues setting the XSRF-TOKEN cookie on repeated safe requests by default' do
        with_forgery_protection do
          get inertia_request_test_path
          expect(set_cookie_header).to include('XSRF-TOKEN')

          get inertia_request_test_path
          expect(set_cookie_header).to include('XSRF-TOKEN')
        end
      end

      it 'rewrites the XSRF-TOKEN cookie even on 304 Not Modified responses by default' do
        with_forgery_protection do
          get http_cache_test_path
          etag = response.headers['ETag']

          get http_cache_test_path, headers: { 'If-None-Match' => etag }

          expect(response.status).to eq(304)
          expect(set_cookie_header).to include('XSRF-TOKEN')
        end
      end

      context 'when xsrf_cookie_refresh is :lazy' do
        with_inertia_config xsrf_cookie_refresh: :lazy

        it 'still sets the XSRF-TOKEN cookie on the first safe request' do
          with_forgery_protection do
            get inertia_request_test_path

            expect(set_cookie_header).to include('XSRF-TOKEN')
          end
        end

        it 'trusts an existing XSRF-TOKEN cookie on repeated safe requests when the session is never loaded' do
          with_forgery_protection do
            get inertia_request_test_path
            expect(set_cookie_header).to include('XSRF-TOKEN')

            get inertia_request_test_path
            expect(set_cookie_header).to be_empty
          end
        end

        # Documents the accepted trade-off of the trust path above: a stale
        # cookie is not detected on session-less safe requests, so a protected
        # request fails loudly until the first session-loading request heals
        # the cookie. Never a CSRF bypass — the cookie is not a server-side
        # validation input.
        it 'blind-trusts a stale cookie on session-less safe requests until a session-loading request heals it' do
          with_forgery_protection do
            cookies['XSRF-TOKEN'] = 'stale-token'

            get inertia_request_test_path
            expect(set_cookie_header).to be_empty

            expect do
              post submit_form_to_test_csrf_path,
                   headers: { 'X-Inertia' => true, 'X-XSRF-Token' => 'stale-token' }
            end.to raise_error(ActionController::InvalidAuthenticityToken)

            get session_loaded_request_test_path
            expect(set_cookie_header).to include('XSRF-TOKEN')
          end
        end

        it 'does not rewrite the XSRF-TOKEN cookie on safe requests when the existing cookie can be validated' do
          with_forgery_protection do
            get session_loaded_request_test_path
            expect(set_cookie_header).to include('XSRF-TOKEN')

            get session_loaded_request_test_path
            expect(set_cookie_header).not_to include('XSRF-TOKEN')
          end
        end

        it 'refreshes the XSRF-TOKEN cookie on safe requests when an invalid cookie can be validated' do
          with_forgery_protection do
            cookies['XSRF-TOKEN'] = 'stale-token'

            get session_loaded_request_test_path

            expect(set_cookie_header).to include('XSRF-TOKEN')
          end
        end

        it 'still refreshes the XSRF-TOKEN cookie on non-safe requests' do
          with_forgery_protection do
            get initialize_session_path
            initial_xsrf_token_cookie = response.cookies['XSRF-TOKEN']

            post submit_form_to_test_csrf_path,
                 headers: { 'X-Inertia' => true, 'X-XSRF-Token' => initial_xsrf_token_cookie }

            expect(set_cookie_header).to include('XSRF-TOKEN')
          end
        end

        # The motivating scenario: HTTP conditional caching (fresh_when/304).
        # fresh_when loads the session (flash is part of the default etag), so
        # the validation path — not blind trust — governs these requests.
        describe 'with HTTP conditional caching' do
          it 'does not rewrite the XSRF-TOKEN cookie on a 304 when the cookie is valid' do
            with_forgery_protection do
              get http_cache_test_path
              expect(set_cookie_header).to include('XSRF-TOKEN')
              etag = response.headers['ETag']

              get http_cache_test_path, headers: { 'If-None-Match' => etag }

              expect(response.status).to eq(304)
              expect(set_cookie_header).not_to include('XSRF-TOKEN')
            end
          end

          it 'refreshes a stale XSRF-TOKEN cookie even on a 304' do
            with_forgery_protection do
              get http_cache_test_path
              etag = response.headers['ETag']
              cookies['XSRF-TOKEN'] = 'stale-token'

              get http_cache_test_path, headers: { 'If-None-Match' => etag }

              expect(response.status).to eq(304)
              expect(set_cookie_header).to include('XSRF-TOKEN')
            end
          end
        end
      end
    end

    describe 'copying an X-XSRF-Token header (Inertia default) into the X-CSRF-Token header (Rails default)' do
      subject { request.headers['X-CSRF-Token'] }
      before { get inertia_request_test_path, headers: headers }

      context 'it is an inertia call' do
        let(:headers) { { 'X-Inertia' => true, 'X-XSRF-Token' => 'foo' } }
        it { is_expected.to eq 'foo' }
      end

      context 'it is not an inertia call' do
        let(:headers) { { 'X-XSRF-Token' => 'foo' } }
        it { is_expected.to eq 'foo' }
      end
    end

    it 'sets the XSRF-TOKEN cookie after the session is cleared during an inertia call' do
      with_forgery_protection do
        get initialize_session_path
        expect(response).to have_http_status(:ok)
        initial_xsrf_token_cookie = response.cookies['XSRF-TOKEN']

        post submit_form_to_test_csrf_path,
             headers: { 'X-Inertia' => true, 'X-XSRF-Token' => initial_xsrf_token_cookie }
        expect(response).to have_http_status(:ok)

        delete clear_session_path, headers: { 'X-Inertia' => true, 'X-XSRF-Token' => initial_xsrf_token_cookie }
        expect(response).to have_http_status(:see_other)
        expect(response.headers['Location']).to eq('http://www.example.com/initialize_session')

        post_logout_xsrf_token_cookie = response.cookies['XSRF-TOKEN']
        expect(post_logout_xsrf_token_cookie).not_to be_nil
        expect(post_logout_xsrf_token_cookie).not_to eq(initial_xsrf_token_cookie)

        post submit_form_to_test_csrf_path,
             headers: { 'X-Inertia' => true, 'X-XSRF-Token' => post_logout_xsrf_token_cookie }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'a non existent route' do
    it 'raises a 404 exception' do
      expect do
        get '/non_existent_route', headers: { 'X-Inertia' => true }
      end.to raise_error(ActionController::RoutingError, /No route matches/)
    end
  end
end
