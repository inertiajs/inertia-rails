# frozen_string_literal: true

RSpec.describe InertiaRails::RawJson do
  describe '#to_json' do
    it 'returns the raw JSON string' do
      raw = described_class.new('[1,2,3]')
      expect(raw.to_json).to eq('[1,2,3]')
    end
  end

  describe '#as_json' do
    let(:json) { '{"items":[1,2,3]}' }

    context 'when the encoder embeds fragments', if: InertiaRails::RawJson.encoder_embeds_fragments? do
      it 'hands the encoder a JSON::Fragment, so the string is never parsed again' do
        raw = described_class.new(json)
        allow(JSON).to receive(:parse).and_call_original

        expect(raw.as_json).to eq(JSON::Fragment.new(json))
        expect(ActiveSupport::JSON.encode(data: raw)).to eq(%({"data":#{json}}))
        expect(JSON).not_to have_received(:parse)
      end
    end

    context 'when the encoder does not embed fragments' do
      before { allow(described_class).to receive(:encoder_embeds_fragments?).and_return(false) }

      it 'returns the parsed data for the encoder to serialize again' do
        raw = described_class.new(json)

        expect(raw.as_json).to eq({ 'items' => [1, 2, 3] })
        expect(ActiveSupport::JSON.encode(data: raw)).to eq(%({"data":#{json}}))
      end
    end
  end

  describe 'embedding in JSON.generate' do
    it 'embeds the raw string without double-escaping' do
      raw = described_class.new('{"items":[1,2,3]}')
      hash = { component: 'Test', props: { data: raw, name: 'Bob' } }

      json = JSON.generate(hash)
      parsed = JSON.parse(json)

      expect(parsed['props']['data']).to eq({ 'items' => [1, 2, 3] })
      expect(parsed['props']['name']).to eq('Bob')
    end

    it 'embeds arrays correctly' do
      raw = described_class.new('[{"id":1},{"id":2}]')
      hash = { items: raw }

      parsed = JSON.parse(JSON.generate(hash))
      expect(parsed['items']).to eq([{ 'id' => 1 }, { 'id' => 2 }])
    end
  end

  describe 'embedding in ActiveSupport::JSON.encode' do
    it 'embeds the raw string without double-escaping' do
      raw = described_class.new('{"items":[1,2,3]}')
      hash = { component: 'Test', props: { data: raw } }

      parsed = JSON.parse(ActiveSupport::JSON.encode(hash))
      expect(parsed['props']['data']).to eq({ 'items' => [1, 2, 3] })
    end
  end

  describe 'embedding in Hash#to_json' do
    it 'embeds the raw string without double-escaping' do
      raw = described_class.new('[1,2,3]')
      hash = { data: raw }

      parsed = JSON.parse(hash.to_json)
      expect(parsed['data']).to eq([1, 2, 3])
    end
  end

  describe '.encoder_embeds_fragments?' do
    it 'is true where Active Support embeds JSON::Fragment values (Active Support 8.1+)' do
      expected = defined?(JSON::Fragment) && ActiveSupport.gem_version >= Gem::Version.new('8.1')
      expect(described_class.encoder_embeds_fragments?).to eq(expected)
    end
  end
end
