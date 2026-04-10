# frozen_string_literal: true

RSpec.describe InertiaRails::RawJson do
  describe '#to_json' do
    it 'returns the raw JSON string' do
      raw = described_class.new('[1,2,3]')
      expect(raw.to_json).to eq('[1,2,3]')
    end
  end

  describe '#as_json' do
    it 'returns self' do
      raw = described_class.new('[1,2,3]')
      expect(raw.as_json).to be(raw)
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
end
