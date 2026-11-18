# frozen_string_literal: true

RSpec.describe InertiaRails::BigIntegers do
  let(:big) { 900_719_925_474_099_988 }
  let(:marker) { { '$bigint' => '900719925474099988' } }

  it 'wraps only integers outside the safe range' do
    expect(described_class.encode(boundary: (2**53) - 1, just_over: 2**53, negative: -big, list: [big])).to eq(
      boundary: 9_007_199_254_740_991, just_over: { '$bigint' => '9007199254740992' },
      negative: { '$bigint' => '-900719925474099988' }, list: [marker]
    )
  end

  it 'looks inside objects, including objects a custom as_json returns' do
    author = Struct.new(:id).new(big)
    post = Struct.new(:id, :author) do
      def as_json(*) = { 'id' => id, 'author' => author }
    end

    serialized = described_class.encode(post: post.new(big, author))

    expect(serialized).to eq(post: { 'id' => marker, 'author' => { 'id' => marker } })
  end

  it 'looks inside JSON fragments' do
    skip 'JSON::Fragment needs json 2.10+' unless defined?(JSON::Fragment)

    expect(described_class.encode(chart: JSON::Fragment.new(%({"id":#{big}})))).to eq(chart: { 'id' => marker })
  end
end
