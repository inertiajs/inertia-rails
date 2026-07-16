# frozen_string_literal: true

RSpec.describe InertiaRails::LocationConversion do
  let(:configuration) { InertiaRails::Configuration.new(convert_external_redirects: true) }

  def convertible?(location, status: 302, request_url: 'http://www.example.com/articles', env: {},
                   config: configuration)
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for(request_url))
    headers = location ? { 'Location' => location } : {}

    described_class.new(env, status, headers, request, config).convertible?
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

      it 'still converts a redirect marked as full page' do
        env = { described_class::FULL_PAGE_REDIRECT_KEY => true }

        expect(convertible?('http://www.example.com/empty_test', env: env)).to be true
      end
    end

    context 'with a full page mark' do
      let(:env) { { described_class::FULL_PAGE_REDIRECT_KEY => true } }

      it 'converts a same-origin redirect' do
        expect(convertible?('http://www.example.com/empty_test', env: env)).to be true
      end

      it 'does not convert a response without a location' do
        expect(convertible?(nil, env: env)).to be false
      end

      # A rescue_from handler can replace the marked redirect with a render.
      it 'does not convert a response whose status is no longer a redirect' do
        expect(convertible?('http://www.example.com/empty_test', status: 200, env: env)).to be false
      end
    end
  end

  describe '.mark_full_page!' do
    it 'marks the env for a convertible status' do
      env = {}

      described_class.mark_full_page!(env, 303)

      expect(env[described_class::FULL_PAGE_REDIRECT_KEY]).to be true
    end

    [307, 308].each do |status|
      it "raises for a method-preserving #{status} status" do
        expect do
          described_class.mark_full_page!({}, status)
        end.to raise_error(ArgumentError, /full_page: true/)
      end
    end
  end

  describe '#to_response' do
    it 'moves the location into X-Inertia-Location, drops content headers, and closes the body' do
      headers = { 'Location' => 'http://external-website.com/some_path',
                  'Content-Type' => 'text/html', 'Content-Length' => '42', 'Set-Cookie' => 'key=value', }
      body = Class.new do
        def close = @closed = true
        def closed? = @closed
      end.new
      request = ActionDispatch::Request.new(Rack::MockRequest.env_for('http://www.example.com/articles'))
      conversion = described_class.new({}, 302, headers, request, configuration)

      status, response_headers, response_body = conversion.to_response(body)

      expect(status).to eq 409
      expect(response_headers).to eq('X-Inertia-Location' => 'http://external-website.com/some_path',
                                     'Set-Cookie' => 'key=value')
      expect(response_body).to eq []
      expect(body.closed?).to be true
    end
  end
end
