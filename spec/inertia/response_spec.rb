# frozen_string_literal: true

RSpec.describe 'InertiaRails::Response', type: :request do
  describe 'inertia location response' do
    context 'with an inertia request' do
      it 'returns a conflict response with the location header' do
        get my_location_path, headers: { 'X-Inertia' => true }

        expect(response.status).to eq 409
        expect(response.headers['X-Inertia-Location']).to eq empty_test_path
        expect(response.headers['Location']).to be_nil
        expect(response.headers['Vary']).to include 'X-Inertia'
        expect(response.body).to be_empty
      end

      it 'returns a conflict response for an external url' do
        get my_external_location_path, headers: { 'X-Inertia' => true }

        expect(response.status).to eq 409
        expect(response.headers['X-Inertia-Location']).to eq 'http://external-website.com/some_path'
        expect(response.headers['Location']).to be_nil
      end
    end

    context 'with a non-inertia request' do
      it 'redirects to the url without a Vary header (same-origin, not cacheable)' do
        get my_location_path

        expect(response.status).to eq 302
        expect(response.headers['Location']).to eq empty_test_url
        expect(response.headers['X-Inertia-Location']).to be_nil
        expect(response.headers['Vary'].to_s).not_to include 'X-Inertia'
      end

      it 'redirects to an external url with a single Vary header from the middleware' do
        get my_external_location_path

        expect(response.status).to eq 302
        expect(response.headers['Location']).to eq 'http://external-website.com/some_path'
        expect(response.headers['X-Inertia-Location']).to be_nil
        # The middleware marks the external redirect; the controller must not also
        # set it, or the header would read "X-Inertia, X-Inertia".
        expect(response.headers['Vary']).to eq 'X-Inertia'
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
