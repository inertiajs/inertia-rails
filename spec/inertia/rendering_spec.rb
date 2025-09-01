# frozen_string_literal: true

RSpec.describe 'rendering inertia views', type: :request do
  subject { response.body }

  let(:controller) { ApplicationController.new.tap { |controller| controller.set_request!(request) } }

  context 'first load' do
    let(:page) { InertiaRails::Renderer.new('TestComponent', controller, request, response, '').send(:page) }

    context 'with props' do
      let(:page) do
        InertiaRails::Renderer.new('TestComponent', controller, request, response, '',
                                   props: { name: 'Brandon', sport: 'hockey' }).send(:page)
      end
      before { get props_path }

      it { is_expected.to include inertia_div(page) }
    end

    context 'with view data' do
      before { get view_data_path }

      it { is_expected.to include inertia_div(page) }
      it { is_expected.to include({ name: 'Brian', sport: 'basketball' }.to_json) }
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

      context 'with non html format' do
        it 'raises UnknownFormat error' do
          expect { get '/inertia_route.json' }.to raise_error(ActionController::UnknownFormat)
        end
      end
    end

    context 'via a resource inertia route' do
      before { get inertia_route_item_path(id: 1) }

      it { is_expected.to include inertia_div(page) }
    end

    context 'via a scoped inertia route' do
      before { get scoped_inertia_route_path }

      it { is_expected.to include inertia_div(page) }
    end

    context 'via a namespaced inertia route' do
      before { get namespaced_inertia_route_path }

      it { is_expected.to include inertia_div(page) }
    end

    context 'with a default component' do
      let(:page) do
        InertiaRails::Renderer.new('inertia_route_with_default_component', controller, request, response,
                                   '').send(:page)
      end

      before { get inertia_route_with_default_component_path }

      it { is_expected.to include inertia_div(page) }
    end

    context 'with a default component resource' do
      let(:page) do
        InertiaRails::Renderer.new('items/inertia_route_with_default_component', controller, request, response,
                                   '').send(:page)
      end

      before { get item_inertia_route_with_default_component_path(item_id: 1) }

      it { is_expected.to include inertia_div(page) }
    end

    context 'with a default component resource on member' do
      let(:page) do
        InertiaRails::Renderer.new(
          'items/inertia_route_with_default_component_on_member', controller, request, response, ''
        ).send(:page)
      end

      before { get inertia_route_with_default_component_on_member_item_path(id: 1) }

      it { is_expected.to include inertia_div(page) }
    end

    context 'with a default component resource on collection' do
      let(:page) do
        InertiaRails::Renderer.new(
          'items/inertia_route_with_default_component_on_collection', controller, request, response, ''
        ).send(:page)
      end

      before { get inertia_route_with_default_component_on_collection_items_path }

      it { is_expected.to include inertia_div(page) }
    end

    context 'with a default component resource & scoped' do
      let(:page) do
        InertiaRails::Renderer.new('items/inertia_route_with_default_component', controller, request, response,
                                   '').send(:page)
      end

      before { get scoped_item_inertia_route_with_default_component_path(item_id: 1) }

      it { is_expected.to include inertia_div(page) }
    end
  end

  context 'subsequent requests' do
    let(:page) do
      InertiaRails::Renderer.new('TestComponent', controller, request, response, '',
                                 props: { name: 'Brandon', sport: 'hockey' }).send(:page)
    end
    let(:headers) { { 'X-Inertia' => true } }

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
    let(:page) do
      InertiaRails::Renderer.new('TestComponent', controller, request, response, '',
                                 props: { sport: 'hockey' }).send(:page)
    end
    let(:headers) do
      {
        'X-Inertia' => true,
        'X-Inertia-Partial-Data' => 'sport',
        'X-Inertia-Partial-Component' => 'TestComponent',
      }
    end

    context 'with the correct partial component header' do
      before { get props_path, headers: headers }

      it { is_expected.to eq page.to_json }
      it { is_expected.to include('hockey') }
    end

    context 'with a non matching partial component header' do
      before do
        headers['X-Inertia-Partial-Component'] = 'NotTheTestComponent'
        get props_path, headers: headers
      end

      it { is_expected.not_to eq page.to_json }
      it 'includes all of the props' do
        is_expected.to include('Brandon')
      end
    end

    context 'with dot notation' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' =>
            'nested.first,nested.deeply_nested.second,nested.deeply_nested.what_about_nil,' \
            'nested.deeply_nested.what_about_empty_hash',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      before { get deeply_nested_props_path, headers: headers }

      it 'only renders the dot notated props' do
        expect(response.parsed_body['props']).to eq(
          'always' => 'always prop',
          'nested' => {
            'first' => 'first nested param',
            'deeply_nested' => {
              'second' => false,
              'what_about_nil' => nil,
              'what_about_empty_hash' => {},
              'deeply_nested_always' => 'deeply nested always prop',
            },
          }
        )
      end
    end

    context 'with both partial and except dot notation' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Component' => 'TestComponent',
          'X-Inertia-Partial-Data' => 'lazy,nested.deeply_nested',
          'X-Inertia-Partial-Except' => 'nested.deeply_nested.first',
        }
      end

      before { get deeply_nested_props_path, headers: headers }

      it 'renders the partial data and excludes the excepted data' do
        expect(response.parsed_body['props']).to eq(
          'always' => 'always prop',
          'lazy' => 'lazy param',
          'nested' => {
            'deeply_nested' => {
              'second' => false,
              'what_about_nil' => nil,
              'what_about_empty_hash' => {},
              'deeply_nested_always' => 'deeply nested always prop',
              'deeply_nested_lazy' => 'deeply nested lazy prop',
            },
          }
        )
      end
    end

    context 'with partial data that includes and excludes the same prop and tries to exclude an always prop' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Component' => 'TestComponent',
          'X-Inertia-Partial-Data' => 'lazy',
          'X-Inertia-Partial-Except' => 'lazy,always',
        }
      end

      before { get deeply_nested_props_path, headers: headers }

      it 'excludes everything but Always props' do
        expect(response.parsed_body['props']).to eq(
          'always' => 'always prop',
          'nested' => {
            'deeply_nested' => {
              'deeply_nested_always' => 'deeply nested always prop',
            },
          }
        )
      end
    end

    context 'with only props that target transformed data' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Component' => 'TestComponent',
          'X-Inertia-Partial-Data' => 'nested.evaluated.first',
        }
      end

      before { get deeply_nested_props_path, headers: headers }

      it 'filters out the entire evaluated prop' do
        expect(response.parsed_body['props']).to eq(
          'always' => 'always prop',
          'nested' => {
            'deeply_nested' => {
              'deeply_nested_always' => 'deeply nested always prop',
            },
          }
        )
      end
    end

    context 'with except props that target transformed data' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Component' => 'TestComponent',
          'X-Inertia-Partial-Except' => 'nested.evaluated.first',
        }
      end

      before { get deeply_nested_props_path, headers: headers }

      it 'renders the entire evaluated prop' do
        expect(response.parsed_body['props']).to eq(
          'always' => 'always prop',
          'flat' => 'flat param',
          'lazy' => 'lazy param',
          'nested_lazy' => { 'first' => 'first nested lazy param' },
          'nested' => {
            'first' => 'first nested param',
            'second' => 'second nested param',
            'evaluated' => {
              'first' => 'first evaluated nested param',
              'second' => 'second evaluated nested param',
            },
            'deeply_nested' => {
              'first' => 'first deeply nested param',
              'second' => false,
              'what_about_nil' => nil,
              'what_about_empty_hash' => {},
              'deeply_nested_always' => 'deeply nested always prop',
              'deeply_nested_lazy' => 'deeply nested lazy prop',
            },
          }
        )
      end
    end
  end

  context 'partial except rendering' do
    let(:headers) do
      {
        'X-Inertia' => true,
        'X-Inertia-Partial-Data' => 'nested,nested_optional',
        'X-Inertia-Partial-Except' => 'nested',
        'X-Inertia-Partial-Component' => 'TestComponent',
      }
    end

    before { get except_props_path, headers: headers }

    it 'returns listed props without excepted' do
      expect(response.parsed_body['props']).to eq(
        'always' => 'always prop',
        'nested_optional' => { 'first' => 'first nested optional param' }
      )
    end

    context 'when except without X-Inertia-Partial-Data' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Except' => 'nested',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      it 'returns all regular and partial props except excepted' do
        expect(response.parsed_body['props']).to eq(
          'flat' => 'flat param',
          'optional' => 'optional param',
          'always' => 'always prop',
          'nested_optional' => { 'first' => 'first nested optional param' }
        )
      end
    end

    context 'when except always prop' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'nested_optional',
          'X-Inertia-Partial-Except' => 'always_prop',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      it 'returns always prop anyway' do
        expect(response.parsed_body['props']).to eq(
          'always' => 'always prop',
          'nested_optional' => { 'first' => 'first nested optional param' }
        )
      end
    end

    context 'when except unknown prop' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'nested_optional',
          'X-Inertia-Partial-Except' => 'unknown',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      it 'returns props' do
        expect(response.parsed_body['props']).to eq(
          'always' => 'always prop',
          'nested_optional' => { 'first' => 'first nested optional param' }
        )
      end
    end

    context 'when excludes with dot notation' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'nested,nested_optional',
          'X-Inertia-Partial-Except' => 'nested.first,nested_optional.first',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      it 'works with dot notation only with simple props' do
        expect(response.parsed_body['props']).to eq(
          'always' => 'always prop',
          'nested' => { 'second' => 'second nested param' },
          'nested_optional' => { 'first' => 'first nested optional param' }
        )
      end
    end
  end

  context 'lazy prop rendering' do
    context 'on first load' do
      let(:page) do
        InertiaRails::Renderer.new('TestComponent', controller, request, response, '',
                                   props: { name: 'Brian' }).send(:page)
      end
      before { get lazy_props_path }

      it { is_expected.to include inertia_div(page) }
    end

    context 'with a partial reload' do
      let(:page) do
        InertiaRails::Renderer.new(
          'TestComponent', controller, request, response, '',
          props: { sport: 'basketball', level: 'worse than he believes', grit: 'intense' }
        ).send(:page)
      end
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'sport,level',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      before { get lazy_props_path, headers: headers }

      it { is_expected.to eq page.to_json }
      it { is_expected.to include('basketball') }
      it { is_expected.to include('worse') }
      it { is_expected.not_to include('intense') }
    end
  end

  context 'optional prop rendering' do
    context 'on first load' do
      let(:page) do
        InertiaRails::Renderer.new('TestComponent', controller, request, response, '',
                                   props: { regular: 1 }).send(:page)
      end
      before { get optional_props_path }

      it { is_expected.to include inertia_div(page) }
    end

    context 'with a partial reload' do
      let(:page) do
        InertiaRails::Renderer.new('TestComponent', controller, request, response, '',
                                   props: { regular: 1, optional: 1 }).send(:page)
      end
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'optional',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      before { get optional_props_path, headers: headers }

      it { is_expected.to eq page.to_json }
    end
  end

  context 'always prop rendering' do
    let(:headers) { { 'X-Inertia' => true } }

    before { get always_props_path, headers: headers }

    it 'returns non-optional props on first load' do
      expect(response.parsed_body['props']).to eq({ 'always' => 'always prop', 'regular' => 'regular prop' })
    end

    context 'with a partial reload' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'optional',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      it 'returns listed and always props' do
        expect(response.parsed_body['props']).to eq({ 'always' => 'always prop', 'optional' => 'optional prop' })
      end
    end
  end

  context 'merged prop rendering' do
    let(:headers) { { 'X-Inertia' => true } }

    before { get merge_props_path, headers: headers }

    it 'returns non-optional props and meta on first load' do
      expect(response.parsed_body['props']).to eq(
        'merge' => 'merge prop', 'match_on' => [{ 'id' => 1 }],
        'deep_merge' => { 'deep' => 'merge prop' }, 'deep_match_on' => { 'deep' => [{ 'id' => 1 }] },
        'regular' => 'regular prop'
      )
      expect(response.parsed_body['mergeProps']).to match_array(
        %w[merge match_on deferred_merge deferred_match_on]
      )
      expect(response.parsed_body['deepMergeProps']).to match_array(
        %w[deep_merge deep_match_on deferred_deep_merge
           deferred_deep_match_on]
      )
      expect(response.parsed_body['deferredProps']).to eq(
        'default' => %w[deferred_merge deferred_match_on
                        deferred_deep_merge deferred_deep_match_on deferred]
      )
      expect(response.parsed_body['matchPropsOn']).to match_array(
        %w[deep_match_on.deep.id deferred_deep_match_on.deep.id
           deferred_match_on.id match_on.id]
      )
    end

    context 'with a partial reload' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'deferred_merge,deferred_deep_merge,deferred_deep_match_on,deferred_match_on',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      it 'returns listed merge props' do
        expect(response.parsed_body['props']).to eq(
          'deferred_merge' => 'deferred and merge prop',
          'deferred_deep_merge' => { 'deep' => 'deferred and merge prop' },
          'deferred_deep_match_on' => { 'deep' => [{ 'id' => 1 }] },
          'deferred_match_on' => [{ 'id' => 1 }]
        )
        expect(response.parsed_body['mergeProps']).to match_array(%w[deferred_merge deferred_match_on])
        expect(response.parsed_body['deepMergeProps']).to match_array(%w[deferred_deep_merge deferred_deep_match_on])
        expect(response.parsed_body['deferredProps']).to be_nil
        expect(response.parsed_body['matchPropsOn']).to match_array(%w[deferred_deep_match_on.deep.id
                                                                       deferred_match_on.id])
      end
    end

    context 'with a reset header' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'deferred_merge,deferred_deep_merge',
          'X-Inertia-Partial-Component' => 'TestComponent',
          'X-Inertia-Reset' => 'deferred_merge,deferred_deep_merge',
        }
      end

      it 'returns listed props' do
        expect(response.parsed_body['props']).to eq(
          'deferred_merge' => 'deferred and merge prop',
          'deferred_deep_merge' => { 'deep' => 'deferred and merge prop' }
        )
        expect(response.parsed_body['mergeProps']).to be_nil
        expect(response.parsed_body['deferredProps']).to be_nil
        expect(response.parsed_body['matchPropsOn']).to be_nil
      end
    end

    context 'with an except header' do
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'deferred_merge,deferred_deep_merge,deep_match_on',
          'X-Inertia-Partial-Except' => 'deferred_merge',
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      it 'returns only the excepted props' do
        expect(response.parsed_body['props']).to eq(
          'deferred_deep_merge' => { 'deep' => 'deferred and merge prop' },
          'deep_match_on' => { 'deep' => [{ 'id' => 1 }] }
        )
        expect(response.parsed_body['mergeProps']).to be_nil
        expect(response.parsed_body['deepMergeProps']).to match_array(%w[deferred_deep_merge deep_match_on])
        expect(response.parsed_body['deferredProps']).to be_nil
        expect(response.parsed_body['matchPropsOn']).to match_array(%w[deep_match_on.deep.id])
      end
    end
  end

  context 'deferred prop rendering' do
    context 'on first load' do
      let(:headers) { { 'X-Inertia' => true } }

      before { get deferred_props_path, headers: headers }

      it 'does not include defer props inside props in first load' do
        expect(response.parsed_body['props']).to eq({ 'name' => 'Brian' })
      end

      it 'returns deferredProps' do
        expect(response.parsed_body['deferredProps']).to eq(
          'default' => %w[level grit],
          'other' => ['sport']
        )
      end
    end

    context 'with a partial reload' do
      let(:page) do
        InertiaRails::Renderer.new(
          'TestComponent', controller, request, response, '',
          props: { sport: 'basketball', level: 'worse than he believes', grit: 'intense' }
        ).send(:page)
      end
      let(:headers) do
        {
          'X-Inertia' => true,
          'X-Inertia-Partial-Data' => 'level,grit', # Simulate default group
          'X-Inertia-Partial-Component' => 'TestComponent',
        }
      end

      before { get deferred_props_path, headers: headers }

      it { is_expected.to eq page.to_json }
      it { is_expected.to include('intense') }
      it { is_expected.to include('worse') }
      it { is_expected.not_to include('basketball') }
      it 'does not deferredProps key in json' do
        expect(response.parsed_body['deferredProps']).to eq(nil)
      end
    end
  end
end

def inertia_div(page)
  "<div id=\"app\" data-page=\"#{CGI.escape_html(page.to_json)}\"></div>"
end
