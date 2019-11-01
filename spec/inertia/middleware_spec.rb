RSpec.describe InertiaRails::Middleware, type: :request do
  context 'the version is stale' do
    it 'tells the client to refresh' do
      get empty_test_path, headers: {'X-Inertia' => true, 'X-Inertia-Version' => 'blkajdf'}

      expect(response.status).to eq 409
      expect(response.headers['X-Inertia-Location']).to eq request.original_url
    end
  end

  context 'a redirect status was passed with an http method that preserves itself on 302 redirect' do
    subject { response.status }

    context 'PUT' do
      before { put redirect_test_path, headers: {'X-Inertia' => true} }

      it { is_expected.to eq 303 }
    end

    context 'PATCH' do
      before { patch redirect_test_path, headers: {'X-Inertia' => true} }

      it { is_expected.to eq 303 }
    end

    context 'DELETE' do
      before { delete redirect_test_path, headers: {'X-Inertia' => true} }

      it { is_expected.to eq 303 }
    end
  end

  context 'a request not originating from inertia' do
    it 'is ignored' do
      get empty_test_path, headers: {'X-Inertia-Version' => 'blkajdf'}

      expect(response.status).to eq 200
    end
  end
end
