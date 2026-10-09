# frozen_string_literal: true

RSpec.describe InertiaRails::Devtools::Redaction do
  it 'drops a query with an undecodable key instead of persisting it raw' do
    expect(described_class.redact_url('http://x/?to%zzken=secret')).to eq 'http://x/?[REDACTED]'
    expect(described_class.redact_url('http://x/?token=%zz')).to eq 'http://x/?token=%5BREDACTED%5D'
  end

  it 'redacts the query of the URL in X-Inertia-Redirect' do
    headers = described_class.redact_headers('x-inertia-redirect' => '/articles?token=secret#comments')

    expect(headers['x-inertia-redirect']).to eq '/articles?token=%5BREDACTED%5D#comments'
  end

  context 'with a dotted key' do
    with_devtools_config redact_keys: %w[token user.name]

    it 'still redacts plain keys inside nested params' do
      expect(described_class.redact_with_log_filters('user' => { 'token' => 'x', 'name' => 'y', 'id' => 1 }))
        .to eq('user' => { 'token' => '[REDACTED]', 'name' => '[REDACTED]', 'id' => 1 })
    end
  end
end
