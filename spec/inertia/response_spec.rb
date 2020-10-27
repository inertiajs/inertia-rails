RSpec.describe 'InertiaRails::Response', type: :request do
  describe 'inertia location response' do
    it 'returns an inertia location response' do
      get my_location_path

      expect(response.status).to eq 409
      expect(response.headers['X-Inertia-Location']).to eq empty_test_path
    end
  end

  describe 'inertia_redirect_to' do
    context 'without an :errors option' do
      it 'behaves like a regular redirect_to' do
        post regular_inertia_redirect_to_path
        expect(response.status).to eq 302
        expect(response.headers['Location']).to eq(empty_test_url)
        expect(session[:inertia_errors]).not_to be
      end
    end

    context 'with an :errors option' do
      # In practice, a GET -> redirect + errors probably shouldn't happen
      context 'with a get request' do
        it 'adds :inertia_errors to the session'  do
          get inertia_redirect_to_with_errors_path
          expect(response.status).to eq 302
          expect(response.headers['Location']).to eq(empty_test_url)
          expect(session[:inertia_errors]).to include('oh bother')
        end
      end

      context 'with a post request' do
        it 'adds :inertia_errors to the session' do
          post inertia_redirect_to_with_errors_path, headers: { 'X-Inertia' => true }
          expect(response.status).to eq 302
          expect(response.headers['Location']).to eq(empty_test_url)
          expect(session[:inertia_errors]).to include('oh bother')
        end
      end
    end
  end
end
