# frozen_string_literal: true

RSpec.describe InertiaRails::Devtools::Redaction do
  it 'drops a query with an undecodable key instead of persisting it raw' do
    expect(described_class.redact_url('http://x/?to%zzken=secret')).to eq 'http://x/?[REDACTED]'
    expect(described_class.redact_url('http://x/?token=%zz')).to eq 'http://x/?token=%5BREDACTED%5D'
  end

  it 'hides fragments containing sensitive parameters, including hash-router queries' do
    %w[access_token=secret&state=public /callback?access_token=secret user%5Btoken%5D=secret
       %61ccess_token=secret state=public;ACCESS_TOKEN=secret access_token=secret?opaque-tail].each do |fragment|
      expect(described_class.redact_url("/callback##{fragment}")).to eq '/callback#[REDACTED]'
    end
    expect(described_class.redact_url('/callback?token=query#state=public&access_token=fragment'))
      .to eq '/callback?token=%5BREDACTED%5D#[REDACTED]'
  end

  it 'applies the app parameter filters to fragments' do
    expect(described_class.redact_url('/callback#ssn=private')).to eq '/callback#[REDACTED]'
  end

  it 'preserves URLs without sensitive fragment parameters byte for byte' do
    %w[/p#top /p?x=a+b#section /p#/route?q=a%20b&sort=-id /p#state=public /p?#].each do |url|
      expect(described_class.redact_url(url)).to eq url
    end
  end

  it 'drops malformed URL parameters without retaining the fragment' do
    expect(described_class.redact_url('/callback#to%zzken=secret')).to eq '/callback?[REDACTED]'
    expect(described_class.redact_url('/callback#token=secret&to%zzken=value')).to eq '/callback#[REDACTED]'
    expect(described_class.redact_url('/callback?to%zzken=value#access_token=secret')).to eq '/callback?[REDACTED]'
  end

  context 'with a dotted key' do
    with_devtools_config redact_keys: %w[token user.name]

    it 'still redacts plain keys inside nested params' do
      expect(described_class.redact_with_log_filters('user' => { 'token' => 'x', 'name' => 'y', 'id' => 1 }))
        .to eq('user' => { 'token' => '[REDACTED]', 'name' => '[REDACTED]', 'id' => 1 })
    end
  end
end
