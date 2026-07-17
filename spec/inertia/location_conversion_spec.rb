# frozen_string_literal: true

RSpec.describe InertiaRails::LocationConversion do
  let(:configuration) { InertiaRails::Configuration.new(convert_external_redirects: true) }

  def convertible?(location, status: 302, request_url: 'http://www.example.com/articles', config: configuration)
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for(request_url))
    headers = location ? { 'Location' => location } : {}

    described_class.new(status, headers, request, config).convertible?
  end

  describe '#convertible?' do
    it 'converts a redirect to a different host' do
      expect(convertible?('http://external-website.com/some_path')).to be true
    end

    it 'converts a redirect to the same host on a different port' do
      expect(convertible?('http://www.example.com:8080/empty_test')).to be true
    end

    it 'converts a redirect to a different scheme on the same host' do
      expect(convertible?('https://www.example.com/empty_test')).to be true
    end

    it 'converts a scheme-relative redirect to a different host' do
      expect(convertible?('//external-website.com/some_path')).to be true
    end

    it 'converts a scheme-relative redirect to the same host when the request port differs' do
      expect(convertible?('//www.example.com/empty_test',
                          request_url: 'http://www.example.com:8080/articles')).to be true
    end

    [301, 303].each do |status|
      it "converts a #{status} redirect" do
        expect(convertible?('http://external-website.com/some_path', status: status)).to be true
      end
    end

    it 'does not convert a same-origin redirect' do
      expect(convertible?('http://www.example.com/empty_test')).to be false
    end

    it 'does not convert a scheme-relative redirect to the same host' do
      expect(convertible?('//www.example.com/empty_test')).to be false
    end

    it 'does not convert a redirect to a relative path' do
      expect(convertible?('/empty_test')).to be false
    end

    it 'does not convert a redirect with an explicit default port' do
      expect(convertible?('http://www.example.com:80/empty_test')).to be false
    end

    it 'does not convert a redirect to the same host with different casing' do
      expect(convertible?('http://WWW.EXAMPLE.COM/empty_test')).to be false
    end

    it 'does not convert a redirect with an invalid location uri' do
      expect(convertible?('http://exa mple.com/path')).to be false
    end

    it 'does not convert a response without a location' do
      expect(convertible?(nil)).to be false
    end

    [307, 308, 200].each do |status|
      it "does not convert a #{status} response" do
        expect(convertible?('http://external-website.com/some_path', status: status)).to be false
      end
    end

    context 'when conversion is disabled' do
      let(:configuration) { InertiaRails::Configuration.new(convert_external_redirects: false) }

      it 'does not convert an external redirect' do
        expect(convertible?('http://external-website.com/some_path')).to be false
      end
    end
  end

  describe '#convert!' do
    it 'moves the location into X-Inertia-Location, drops content headers, and closes the body' do
      headers = { 'Location' => 'http://external-website.com/some_path',
                  'Content-Type' => 'text/html', 'Content-Length' => '42', 'Set-Cookie' => 'key=value', }
      body = Class.new do
        def close = @closed = true
        def closed? = @closed
      end.new
      request = ActionDispatch::Request.new(Rack::MockRequest.env_for('http://www.example.com/articles'))
      conversion = described_class.new(302, headers, request, configuration)

      status, response_headers, response_body = conversion.convert!(body)

      expect(status).to eq 409
      expect(response_headers).to eq('X-Inertia-Location' => 'http://external-website.com/some_path',
                                     'Set-Cookie' => 'key=value')
      expect(response_body).to eq []
      expect(body.closed?).to be true
    end
  end
end
