# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InertiaRails::StreamName do
  let(:verifier) { ActiveSupport::MessageVerifier.new('test-key', digest: 'SHA256', serializer: JSON) }

  before do
    allow(InertiaRails).to receive(:signed_stream_verifier).and_return(verifier)
  end

  describe '.stream_name_from' do
    it 'converts a string' do
      expect(described_class.stream_name_from('projects')).to eq('projects')
    end

    it 'converts a symbol' do
      expect(described_class.stream_name_from(:projects)).to eq('projects')
    end

    it 'converts an array by joining with colon' do
      expect(described_class.stream_name_from([:projects, :tasks])).to eq('projects:tasks')
    end

    it 'uses to_gid_param for GlobalID-capable objects' do
      model = double(to_gid_param: 'gid://app/Project/1')
      expect(described_class.stream_name_from(model)).to eq('gid://app/Project/1')
    end

    it 'falls back to to_param for non-GlobalID objects' do
      model = double(to_param: '42')
      expect(described_class.stream_name_from(model)).to eq('42')
    end

    it 'handles mixed arrays with models and symbols' do
      model = double(to_gid_param: 'gid://app/Chat/5')
      expect(described_class.stream_name_from([model, :messages])).to eq('gid://app/Chat/5:messages')
    end

    it 'strips nil elements from arrays' do
      expect(described_class.stream_name_from([:projects, nil, :tasks])).to eq('projects:tasks')
    end
  end

  describe '.signed_stream_name' do
    it 'returns a signed string' do
      signed = described_class.signed_stream_name('projects')
      expect(signed).to be_a(String)
      expect(signed).not_to eq('projects')
    end

    it 'can be verified back to the original stream name' do
      signed = described_class.signed_stream_name('projects')
      expect(verifier.verified(signed)).to eq('projects')
    end

    it 'works with array streamables' do
      signed = described_class.signed_stream_name([:chat, :messages])
      expect(verifier.verified(signed)).to eq('chat:messages')
    end
  end

  describe '.verified_stream_name' do
    it 'verifies a valid signed name' do
      signed = verifier.generate('projects')
      expect(described_class.verified_stream_name(signed)).to eq('projects')
    end

    it 'returns nil for a tampered name' do
      expect(described_class.verified_stream_name('tampered')).to be_nil
    end

    it 'returns nil for nil' do
      expect(described_class.verified_stream_name(nil)).to be_nil
    end
  end
end
