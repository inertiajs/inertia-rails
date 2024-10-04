RSpec.describe 'rendering inertia views', type: :request do
  subject { response.body }

  let(:controller) { ApplicationController.new }

  context 'first load' do
    let(:page) { InertiaRails::Renderer.new('TestComponent', controller, request, response, '').send(:page) }
    
    context 'with props' do
      let(:page) { InertiaRails::Renderer.new('TestComponent', controller, request, response, '', props: {name: 'Brandon', sport: 'hockey'}).send(:page) }
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

    it 'has the proper status code' do
      get component_path
      expect(response.status).to eq 200
    end

    context 'via an inertia route' do
      before { get inertia_route_path }

      it { is_expected.to include inertia_div(page) }
    end
  end

  context 'subsequent requests' do
    let(:page) { InertiaRails::Renderer.new('TestComponent', controller, request, response, '', props: {name: 'Brandon', sport: 'hockey'}).send(:page) }
    let(:headers) { {'X-Inertia' => true} }

    before { get props_path, headers: headers }

    it { is_expected.to eq page.to_json }

    it 'has the proper headers' do
      expect(response.headers['X-Inertia']).to eq 'true'
      expect(response.headers['Vary']).to eq 'X-Inertia'
      expect(response.headers['Content-Type']).to eq 'application/json; charset=utf-8'
    end

    it 'has the proper body' do
      expect(JSON.parse(response.body)).to include('url' => '/props')
    end

    it 'has the proper status code' do
      expect(response.status).to eq 200
    end
  end

  context 'partial rendering' do
    let (:page) {
      InertiaRails::Renderer.new('TestComponent', controller, request, response, '', props: { sport: 'hockey' }).send(:page)
    }
    let(:headers) {{
      'X-Inertia' => true,
      'X-Inertia-Partial-Data' => 'sport',
      'X-Inertia-Partial-Component' => 'TestComponent',
    }}

    context 'with the correct partial component header' do
      before { get props_path, headers: headers }

      it { is_expected.to eq page.to_json }
      it { is_expected.to include('hockey') }
    end

    context 'with a non matching partial component header' do
      before {
        headers['X-Inertia-Partial-Component'] = 'NotTheTestComponent'
        get props_path, headers: headers
      }

      it { is_expected.not_to eq page.to_json }
      it 'includes all of the props' do
        is_expected.to include('Brandon')
      end
    end
  end

  context 'lazy prop rendering' do
    context 'on first load' do
      let (:page) {
        InertiaRails::Renderer.new('TestComponent', controller, request, response, '', props: { name: 'Brian'}).send(:page)
      }
      before { get lazy_props_path }

      it { is_expected.to include inertia_div(page) }
    end

    context 'with a partial reload' do
      let (:page) {
        InertiaRails::Renderer.new('TestComponent', controller, request, response, '', props: { sport: 'basketball', level: 'worse than he believes', grit: 'intense'}).send(:page)
      }
      let(:headers) {{
        'X-Inertia' => true,
        'X-Inertia-Partial-Data' => 'sport,level',
        'X-Inertia-Partial-Component' => 'TestComponent',
      }}

      before { get lazy_props_path, headers: headers }

      it { is_expected.to eq page.to_json }
      it { is_expected.to include('basketball') }
      it { is_expected.to include('worse') }
      it { is_expected.not_to include('intense') }
    end
  end

  context 'deferred prop rendering' do
    context 'on first load' do
      let (:page) {
        InertiaRails::Renderer.new('TestComponent', controller, request, response, '', props: { name: 'Brian', sport: 'basketball', level: 'worse than he believes', grit: 'intense' }).send(:page)
      }
      let(:headers) { { 'X-Inertia' => true } }
      before { get deferred_props_path, headers: headers }

      it "does not include defer props inside props in first load" do
        expect(JSON.parse(response.body)["props"]).to eq({ "name" => 'Brian' })
      end

      it "returns deferredProps" do
        expect(JSON.parse(response.body)["deferredProps"]).to eq(
                                                                "default" => ["level", "grit"],
                                                                "other" => ["sport"]
                                                              )
      end
    end

    context 'with a partial reload' do
      let (:page) {
        InertiaRails::Renderer.new('TestComponent', controller, request, response, '', props: { sport: 'basketball', level: 'worse than he believes', grit: 'intense' }).send(:page)
      }
      let(:headers) { {
        'X-Inertia' => true,
        'X-Inertia-Partial-Data' => 'level,grit', # Simulate default group
        'X-Inertia-Partial-Component' => 'TestComponent',
      } }

      before { get deferred_props_path, headers: headers }

      it { is_expected.to eq page.to_json }
      it { is_expected.to include('intense') }
      it { is_expected.to include('worse') }
      it { is_expected.not_to include('basketball') }
      it "does not deferredProps key in json" do
        expect(JSON.parse(response.body)["deferredProps"]).to eq(nil)
      end
    end
  end
end

def inertia_div(page)
  "<div id=\"app\" data-page=\"#{CGI::escape_html(page.to_json)}\"></div>"
end
