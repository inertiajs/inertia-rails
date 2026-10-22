# frozen_string_literal: true

RSpec.describe InertiaRails::RawJson do
  describe '#to_json' do
    it 'returns the raw JSON string' do
      raw = described_class.new('[1,2,3]')
      expect(raw.to_json).to eq('[1,2,3]')
    end
  end

  describe '#as_json' do
    it 'returns a value compatible with JSON encoding' do
      raw = described_class.new('[1,2,3]')
      expect { ActiveSupport::JSON.encode(data: raw) }.not_to raise_error
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

  describe '.fragment_embeddable?' do
    it 'is true where Active Support embeds JSON::Fragment values (Active Support 8.1+)' do
      expected = defined?(JSON::Fragment) && ActiveSupport.gem_version >= Gem::Version.new('8.1')
      expect(described_class.fragment_embeddable?).to eq(expected)
    end
  end

  describe '.wrap' do
    let(:json) { '{"items":[1,2,3]}' }

    it 'embeds the string in ActiveSupport::JSON.encode and JSON.generate' do
      wrapped = described_class.wrap(json)

      expect(ActiveSupport::JSON.encode(data: wrapped)).to eq(%({"data":#{json}}))
      expect(JSON.generate(data: wrapped)).to eq(%({"data":#{json}}))
    end

    context 'when the encoder embeds fragments', if: InertiaRails::RawJson.fragment_embeddable? do
      it 'returns a JSON::Fragment that is never parsed again' do
        wrapped = described_class.wrap(json)
        expect(wrapped).to be_a(JSON::Fragment)

        allow(JSON).to receive(:parse).and_call_original
        ActiveSupport::JSON.encode(data: wrapped)
        expect(JSON).not_to have_received(:parse)
      end
    end

    context 'when the encoder does not embed fragments' do
      before { allow(described_class).to receive(:fragment_embeddable?).and_return(false) }

      it 'returns a RawJson' do
        expect(described_class.wrap(json)).to be_a(described_class)
      end
    end
  end
end
