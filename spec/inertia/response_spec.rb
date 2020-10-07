RSpec.describe 'Inertia::Response', type: :request do
  describe 'inertia location response' do
    it 'returns an inertia location response' do
      get my_location_path

      expect(response.status).to eq 409
      expect(response.headers['X-Inertia-Location']).to eq empty_test_path
    end
  end  
end
