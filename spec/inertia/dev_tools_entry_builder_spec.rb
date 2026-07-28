# frozen_string_literal: true

RSpec.describe InertiaRails::DevTools::EntryBuilder do
  def build_entry(body:, content_type:)
    request = ActionDispatch::TestRequest.create

    described_class.new(
      request: request,
      status: 200,
      headers: { 'Content-Type' => content_type },
      body: body,
      id: SecureRandom.uuid,
      batch_id: nil,
      started_at: Process.clock_gettime(Process::CLOCK_MONOTONIC)
    ).build
  end

  it 'captures ordinary JSON response bodies' do
    entry = build_entry(body: ['{"ok":true}'], content_type: 'application/json')

    expect(entry.dig('http', 'responseBody')).to eq(
      'status' => 'present',
      'value' => { 'ok' => true }
    )
  end

  it 'omits binary response bodies' do
    entry = build_entry(body: ["\x00\x01"], content_type: 'application/octet-stream')

    expect(entry.dig('http', 'responseBody')).to eq(
      'status' => 'omitted',
      'reason' => 'non-textual'
    )
  end

  it 'omits streamed response bodies without consuming them' do
    streamed_body = Class.new do
      def each
        yield 'streamed'
      end
    end.new

    entry = build_entry(body: streamed_body, content_type: 'text/plain')

    expect(entry.dig('http', 'responseBody')).to eq(
      'status' => 'omitted',
      'reason' => 'streamed'
    )
  end

  it 'omits response bodies over the capture limit' do
    body = ['x' * (described_class::BODY_LIMIT + 1)]
    entry = build_entry(body: body, content_type: 'text/plain')

    expect(entry.dig('http', 'responseBody')).to eq(
      'status' => 'omitted',
      'reason' => 'too-large'
    )
  end
end

RSpec.describe InertiaRails::DevTools::InjectingBody do
  it 'injects before the closing body tag and preserves the remaining response' do
    source = ['<html><body>hello', '</body></html>']
    output = described_class.new(source, '<script>id</script>').to_enum.to_a

    expect(output.join).to eq('<html><body>hello<script>id</script></body></html>')
  end
end
