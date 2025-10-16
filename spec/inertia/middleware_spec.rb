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
