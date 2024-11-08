RSpec.describe 'rendering inertia views', type: :request do
  subject { response.body }

  let(:controller) { ApplicationController.new.tap { |controller| controller.set_request!(request) } }

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

    describe 'headers' do
      context 'when no other Vary header is present' do
        it 'has the proper headers' do
          get component_path

          expect(response.headers['X-Inertia']).to be_nil
          expect(response.headers['Vary']).to eq 'X-Inertia'
          expect(response.headers['Content-Type']).to eq 'text/html; charset=utf-8'
        end
      end

      context 'when another Vary header is present' do
        it 'has the proper headers' do
          get vary_header_path

          expect(response.headers['X-Inertia']).to be_nil
          expect(response.headers['Vary']).to eq 'Accept-Language, X-Inertia'
          expect(response.headers['Content-Type']).to eq 'text/html; charset=utf-8'
        end
      end
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
      expect(response.parsed_body).to include('url' => '/props')
    end

    it 'has the proper status code' do
      expect(response.status).to eq 200
    end
  end

  context 'partial rendering' do
    let(:page) {
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

  context 'partial except rendering' do
    let(:headers) do
      {
        'X-Inertia' => true,
        'X-Inertia-Partial-Data' => 'nested,nested_lazy',
        'X-Inertia-Partial-Except' => 'nested',
        'X-Inertia-Partial-Component' => 'TestComponent',
      }
    end

    before { get except_props_path, headers: headers }

    it 'returns listed props without excepted' do
      expect(response.parsed_body['props']).to eq(
        'always' => 'always prop',
        'nested_lazy' => { 'first' => 'first nested lazy param' },
      )
    end

    context 'when except without X-Inertia-Partial-Data' do
      let(:headers) {{
        'X-Inertia' => true,
        'X-Inertia-Partial-Except' => 'nested',
        'X-Inertia-Partial-Component' => 'TestComponent',
      }}

      it 'returns all regular and partial props except excepted' do
        expect(response.parsed_body['props']).to eq(
          'flat' => 'flat param',
          'lazy' => 'lazy param',
          'always' => 'always prop',
          'nested_lazy' => { 'first' => 'first nested lazy param' },
        )
      end
    end

    context 'when except always prop' do
      let(:headers) {{
        'X-Inertia' => true,
        'X-Inertia-Partial-Data' => 'nested_lazy',
        'X-Inertia-Partial-Except' => 'always_prop',
        'X-Inertia-Partial-Component' => 'TestComponent',
      }}

      it 'returns always prop anyway' do
        expect(response.parsed_body['props']).to eq(
          'always' => 'always prop',
          'nested_lazy' => { 'first' => 'first nested lazy param' },
        )
      end
    end

    context 'when except unknown prop' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'nested_lazy',
          'X-Inertia-Partial-Except' => 'unknown',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      it 'returns props' do
        expect(response.parsed_body['props']).to eq(
          'always' => 'always prop',
          'nested_lazy' => { 'first' => 'first nested lazy param' },
        )
      end
    end

    context 'when excludes with dot notation' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'nested,nested_lazy',
          'X-Inertia-Partial-Except' => 'nested.first,nested_lazy.first',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      it 'works with dot notation only with simple props' do
        expect(response.parsed_body['props']).to eq(
          'always' => 'always prop',
          'nested' => { 'second' => 'second nested param' },
          'nested_lazy' => { 'first' => 'first nested lazy param' },
        )
      end
    end
  end

  context 'lazy prop rendering' do
    context 'on first load' do
      let(:page) {
        InertiaRails::Renderer.new('TestComponent', controller, request, response, '', props: { name: 'Brian'}).send(:page)
      }
      before { get lazy_props_path }

      it { is_expected.to include inertia_div(page) }
    end

    context 'with a partial reload' do
      let(:page) {
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

  context 'always prop rendering' do
    let(:headers) { { 'X-Inertia' => true } }

    before { get always_props_path, headers: headers }

    it "returns non-optional props on first load" do
      expect(response.parsed_body["props"]).to eq({"always" => 'always prop', "regular" => 'regular prop' })
    end

    context 'with a partial reload' do
      let(:headers) {{
        'X-Inertia' => true,
        'X-Inertia-Partial-Data' => 'lazy',
        'X-Inertia-Partial-Component' => 'TestComponent',
      }}

      it "returns listed and always props" do
        expect(response.parsed_body["props"]).to eq({"always" => 'always prop', "lazy" => 'lazy prop' })
      end
    end
  end

  context 'merged prop rendering' do
    let(:headers) { { 'X-Inertia' => true } }

    before { get merge_props_path, headers: headers }

    it 'returns non-optional props and meta on first load' do
      expect(response.parsed_body['props']).to eq('merge' => 'merge prop', 'regular' => 'regular prop')
      expect(response.parsed_body['mergeProps']).to match_array(%w[merge deferred_merge])
      expect(response.parsed_body['deferredProps']).to eq('default' => %w[deferred_merge deferred])
    end

    context 'with a partial reload' do
      let(:headers) {{
        'X-Inertia' => true,
        'X-Inertia-Partial-Data' => 'deferred_merge',
        'X-Inertia-Partial-Component' => 'TestComponent',
      }}

      it 'returns listed and merge props' do
        expect(response.parsed_body['props']).to eq({'deferred_merge' => 'deferred and merge prop'})
        expect(response.parsed_body['mergeProps']).to match_array(%w[merge deferred_merge])
        expect(response.parsed_body['deferredProps']).to be_nil
      end
    end

    context 'with a reset header' do
      let(:headers) {{
        'X-Inertia' => true,
        'X-Inertia-Partial-Data' => 'deferred_merge',
        'X-Inertia-Partial-Component' => 'TestComponent',
        'X-Inertia-Reset' => 'deferred_merge'
      }}

      it 'returns listed and merge props' do
        expect(response.parsed_body['props']).to eq({'deferred_merge' => 'deferred and merge prop'})
        expect(response.parsed_body['mergeProps']).to match_array(%w[merge])
        expect(response.parsed_body['deferredProps']).to be_nil
      end
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
