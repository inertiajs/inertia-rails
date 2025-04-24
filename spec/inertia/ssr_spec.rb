# frozen_string_literal: true

RSpec.describe 'inertia ssr', type: :request do
  context 'ssr is enabled' do
    with_inertia_config ssr_enabled: true, ssr_url: 'ssr-url', version: '1.0'

    context 'with a successful ssr response' do
      before do
        allow(Net::HTTP).to receive(:post)
          .with(
            URI('ssr-url/render'),
            {
              component: 'TestComponent',
              props: { name: 'Brandon', sport: 'hockey' },
              url: props_path,
              version: '1.0',
              encryptHistory: false,
              clearHistory: false,
              meta: []
            }.to_json,
            'Content-Type' => 'application/json'
          )
          .and_return(double(
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
        get props_path, headers: { 'X-Inertia' => true, 'X-Inertia-Version' => '1.0' }

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
              props: { name: 'Brandon', sport: 'hockey' },
              url: props_path,
              version: '1.0',
              encryptHistory: false,
              clearHistory: false,
              meta: []
            }.to_json,
            'Content-Type' => 'application/json'
          )
          .and_raise('uh oh')
      end

      it 'renders inertia without ssr as a fallback' do
        get props_path

        # rubocop:disable Layout/LineLength
        expect(response.body).to include '<div id="app" data-page="{&quot;component&quot;:&quot;TestComponent&quot;,&quot;props&quot;:{&quot;name&quot;:&quot;Brandon&quot;,&quot;sport&quot;:&quot;hockey&quot;},&quot;url&quot;:&quot;/props&quot;,&quot;version&quot;:&quot;1.0&quot;,&quot;encryptHistory&quot;:false,&quot;clearHistory&quot;:false,&quot;meta&quot;:[]}"></div>'
        # rubocop:enable Layout/LineLength
      end
    end
  end
end
