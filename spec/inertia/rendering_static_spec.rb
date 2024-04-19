RSpec.describe 'rendering inertia static views', type: :request do
  subject { response.body }

  let(:controller_path) {}
  let(:action_name) {}

  let(:controller) {
    double(
      'Controller',
       inertia_view_assigns: {},
       controller_path: controller_path,
       action_name: action_name
    )
  }

  before do
    allow(controller).to receive(:render_to_string) do |view, **kwargs|
      render_view_file(view, **kwargs)
    end
  end

  context 'first load' do
    let(:static_view) { }
    let(:page) { InertiaRails::Renderer.new({ static: static_view }, controller, request, response, '').send(:page) }

    context 'with provided view' do
      let(:static_view) { 'inertia_render_static_test/custom_view' }

      it 'has the proper status code' do
        get static_component_path
        expect(response.status).to eq 200
      end

      it 'renders the static view as a props' do
        get static_component_path
        is_expected.to include(CGI::escape_html({ body: render_view_file(static_view) }.to_json))
      end

      it 'renders the page attribute' do
        get static_component_path
        is_expected.to include CGI::escape_html(page.to_json)
      end
    end

    context 'with default view' do
      let(:static_view) { true }
      let(:action_name) { 'default_view' }
      let(:controller_path) { 'inertia_render_static_test' }


      it 'has the proper status code' do
        get static_default_component_path
        expect(response.status).to eq 200
      end

      it 'renders the static view as a props' do
        get static_default_component_path
        is_expected.to include(CGI::escape_html({ body: render_view_file('inertia_render_static_test/default_view') }.to_json))
      end

      it 'renders the page attribute' do
        get static_default_component_path
        is_expected.to include CGI::escape_html(page.to_json)
      end
    end
  end

  context 'subsequent requests' do
    let(:static_view) { 'inertia_render_static_test/custom_view' }
    let(:page) { InertiaRails::Renderer.new({ static: static_view }, controller, request, response, '', props: { }).send(:page) }
    let(:headers) { { 'X-Inertia' => true } }

    before { get static_component_path, headers: headers }

    it { is_expected.to eq page.to_json }

    it 'has the proper headers' do
      expect(response.headers['X-Inertia']).to eq 'true'
      expect(response.headers['Vary']).to eq 'Accept'
      expect(response.headers['Content-Type']).to eq 'application/json; charset=utf-8'
    end

    it 'has the proper body' do
      expect(JSON.parse(response.body)).to include('url' => '/static_component')
    end

    it 'has the proper body in props' do
      expect(JSON.parse(response.body)).to include({ 'props' => { 'body' => page[:props][:body] } })
    end

    it 'has the proper status code' do
      expect(response.status).to eq 200
    end
  end
end
