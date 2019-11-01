RSpec.describe 'rendering inertia views', type: :request do
  subject { response.body }

  context 'first load' do
    let(:page) { InertiaRails::Renderer.new('TestComponent', '', request, response, '', props: nil, view_data: nil).send(:page) }
    
    context 'with props' do
      let(:page) { InertiaRails::Renderer.new('TestComponent', '', request, response, '', props: {name: 'Brandon', sport: 'hockey'}, view_data: nil).send(:page) }
      before { get props_path }

      it { is_expected.to include inertia_div(page) }
    end

    context 'with view data' do
      before { get view_data_path }

      it { is_expected.to include inertia_div(page) }
      it { is_expected.to include({name: 'Brian', sport: 'basketball'}.to_json) }
    end

    context 'with no data' do
      before { get component_path }

      it { is_expected.to include inertia_div(page) }
    end
  end

  context 'subsequent requests' do
    let(:page) { InertiaRails::Renderer.new('TestComponent', '', request, response, '', props: {name: 'Brandon', sport: 'hockey'}, view_data: nil).send(:page) }
    let(:headers) { {'X-Inertia' => true} }

    before { get props_path, headers: headers }

    it { is_expected.to eq page.to_json }


    it 'has the proper headers' do
      expect(response.headers['X-Inertia']).to eq 'true'
      expect(response.headers['Vary']).to eq 'Accept'
      expect(response.headers['Content-Type']).to eq 'application/json; charset=utf-8'
    end
  end
end

def inertia_div(page)
  "<div id=\"app\" data-page=\"#{CGI::escape_html(page.to_json)}\"></div>"
end
