RSpec.describe 'Inertia::Request', type: :request do
  describe 'it tests whether a call is an inertia call' do
    subject { response.status }
    before { get inertia_request_test_path, headers: headers }

    context 'it is an inertia call' do
      let(:headers) { {'X-Inertia' => true} }

      it { is_expected.to eq 202 }
    end

    context 'it is not an inertia call' do
      let(:headers) { Hash.new }

      it { is_expected.to eq 200 }
    end
  end

  describe 'it tests whether a call is a partial inertia call' do
    subject { response.status }
    before { get inertia_partial_request_test_path, headers: headers }

    context 'it is a partial inertia call' do
      let(:headers) { { 'X-Inertia' => true, 'X-Inertia-Partial-Data' => 'foo,bar,baz' } }

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
end
