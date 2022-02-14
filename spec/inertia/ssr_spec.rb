RSpec.describe 'inertia ssr', type: :request do
  context 'ssr is enabled' do
    before do
      InertiaRails.reset!
      InertiaRails.configure do |config|
        config.ssr_enabled = true
        config.ssr_url = 'ssr-url'
        config.version = '1.0'
      end
    end

    it 'returns the result of the ssr call' do
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


      get props_path


      expect(response.body).to include('<title>Title works</title>')
      expect(response.body).to include('<div>Test works</div>')
    end
  end
end