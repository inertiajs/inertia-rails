require 'net/http'

RSpec.describe 'inertia ssr', type: :request do
  context 'ssr is enabled' do
    before do
      InertiaRails.configure do |config|
        config.ssr_enabled = true
        config.ssr_url = 'ssr-url'
        config.version = '1.0'
      end
    end

    context 'with a successful ssr response' do
      before do
        allow(Net::HTTP).to receive(:post)
        .with(
          URI('ssr-url/render'),
          {
            component: 'TestComponent',
            props: {name: 'Brandon', sport: 'hockey'},
            url: props_path,
            version: '1.0',
          }.to_json,
          'Content-Type' => 'application/json'
        )
        .and_return(OpenStruct.new(
          body: {
            body: '<div>Test works</div>',
            head: ['<title>Title works</title>'],
          }.to_json
        ))
      end

      it 'returns the result of the ssr call' do
        get props_path

        expect(response.body).to include('<title>Title works</title>')
        expect(response.body).to include('<div>Test works</div>')
        expect(response.headers['Content-Type']).to eq 'text/html; charset=utf-8'
      end

      it 'allows inertia to take over when inertia headers are passed' do
        get props_path, headers: {'X-Inertia' => true, 'X-Inertia-Version' => '1.0'}

        expect(response.headers['Vary']).to eq 'X-Inertia'
        expect(response.headers['Content-Type']).to eq 'application/json; charset=utf-8'
      end
    end

    context 'the ssr server fails for some reason' do
      before do
        allow(Net::HTTP).to receive(:post)
        .with(
          URI('ssr-url/render'),
          {
            component: 'TestComponent',
            props: {name: 'Brandon', sport: 'hockey'},
            url: props_path,
            version: '1.0',
          }.to_json,
          'Content-Type' => 'application/json'
        )
        .and_raise('uh oh')
      end

      it 'renders inertia without ssr as a fallback' do
        get props_path

        expect(response.body).to include '<div id="app" data-page="{&quot;component&quot;:&quot;TestComponent&quot;,&quot;props&quot;:{&quot;name&quot;:&quot;Brandon&quot;,&quot;sport&quot;:&quot;hockey&quot;},&quot;url&quot;:&quot;/props&quot;,&quot;version&quot;:&quot;1.0&quot;}"></div>'
      end
    end
  end
end
