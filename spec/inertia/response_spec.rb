# frozen_string_literal: true

RSpec.describe 'InertiaRails::Response', type: :request do
  describe 'inertia location response' do
    context 'with an inertia request' do
      it 'returns a conflict response with the location header' do
        get my_location_path, headers: { 'X-Inertia' => true }

        expect(response.status).to eq 409
        expect(response.headers['X-Inertia-Location']).to eq empty_test_path
        expect(response.headers['Location']).to be_nil
        expect(response.body).to be_empty
      end

      it 'returns a conflict response for an external url' do
        get my_external_location_path, headers: { 'X-Inertia' => true }

        expect(response.status).to eq 409
        expect(response.headers['X-Inertia-Location']).to eq 'http://external-website.com/some_path'
        expect(response.headers['Location']).to be_nil
      end

      context 'when the asset version is stale' do
        with_inertia_config version: '1.0'

        it 'is not overridden by a forced refresh' do
          get my_location_path, headers: { 'X-Inertia' => true, 'X-Inertia-Version' => 'stale' }

          expect(response.status).to eq 409
          expect(response.headers['X-Inertia-Location']).to eq empty_test_path
        end
      end
    end

    context 'with a non-inertia request' do
      it 'redirects to the url' do
        get my_location_path

        expect(response.status).to eq 302
        expect(response.headers['Location']).to eq empty_test_url
        expect(response.headers['X-Inertia-Location']).to be_nil
      end

      it 'redirects to an external url' do
        get my_external_location_path

        expect(response.status).to eq 302
        expect(response.headers['Location']).to eq 'http://external-website.com/some_path'
        expect(response.headers['X-Inertia-Location']).to be_nil
      end
    end
  end

  describe 'redirect_to' do
    context 'with an [:inertia][:errors] option' do
      # In practice, a GET -> redirect + errors probably shouldn't happen
      context 'with a get request' do
        it 'adds :inertia_errors to the session' do
          get redirect_with_inertia_errors_path
          expect(response.status).to eq 302
          expect(response.headers['Location']).to eq(empty_test_url)
          expect(session[:inertia_errors]).to include({ uh: 'oh' })
        end
      end

      context 'with a post request' do
        it 'adds :inertia_errors to the session' do
          post redirect_with_inertia_errors_path, headers: { 'X-Inertia' => true }
          expect(response.status).to eq 302
          expect(response.headers['Location']).to eq(empty_test_url)
          expect(session[:inertia_errors]).to include({ uh: 'oh' })
        end

        it 'serializes :inertia_errors to the session' do
          post redirect_with_inertia_error_object_path,
               headers: { 'X-Inertia' => true }

          expect(response.status).to eq 302
          expect(response.headers['Location']).to eq(empty_test_url)
          expect(session[:inertia_errors]).to include({ uh: 'oh' })
        end
      end
    end

    context 'with an [:inertia][:full_page] option' do
      context 'with an inertia request' do
        it 'converts the redirect to a conflict response with the location header' do
          get full_page_redirect_test_path, headers: { 'X-Inertia' => true }

          expect(response.status).to eq 409
          expect(response.headers['X-Inertia-Location']).to eq empty_test_url
          expect(response.headers['Location']).to be_nil
        end

        it 'keeps cookies and flash set alongside the redirect' do
          get full_page_redirect_with_cookie_test_path, headers: { 'X-Inertia' => true }

          expect(response.status).to eq 409
          expect(cookies['full_page_cookie']).to eq 'hello'
          expect(flash[:notice]).to eq 'converted'
        end

        context 'when automatic conversion is disabled' do
          with_inertia_config convert_external_redirects: false

          it 'still converts the redirect' do
            get full_page_redirect_test_path, headers: { 'X-Inertia' => true }

            expect(response.status).to eq 409
            expect(response.headers['X-Inertia-Location']).to eq empty_test_url
          end
        end

        context 'when the asset version is stale' do
          with_inertia_config version: '1.0'

          it 'prefers the conversion over a forced refresh' do
            get full_page_redirect_test_path, headers: { 'X-Inertia' => true, 'X-Inertia-Version' => 'stale' }

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
  end

  describe 'redirect_back' do
    context 'with an [:inertia][:errors] option' do
      context 'with a post request' do
        it 'adds :inertia_errors to the session' do
          post(
            redirect_back_with_inertia_errors_path,
            headers: {
              'X-Inertia' => true,
              'HTTP_REFERER' => 'http://www.example.com/current-path',
            }
          )
          expect(response.status).to eq 302
          expect(response.headers['Location']).to eq('http://www.example.com/current-path')
          expect(session[:inertia_errors]).to include({ go: 'back!' })
        end
      end
    end
  end

  describe 'redirect_back_or_to' do
    context 'with an [:inertia][:errors] option' do
      context 'with a post request' do
        it 'adds :inertia_errors to the session' do
          skip('Requires Rails 7.0 or higher') if Rails.version < '7'

          post(
            redirect_back_or_to_with_inertia_errors_path,
            headers: {
              'X-Inertia' => true,
              'HTTP_REFERER' => 'http://www.example.com/current-path',
            }
          )
          expect(response.status).to eq 302
          expect(response.headers['Location']).to eq('http://www.example.com/current-path')
          expect(session[:inertia_errors]).to include({ go: 'back!' })
        end
      end
    end
  end
end
