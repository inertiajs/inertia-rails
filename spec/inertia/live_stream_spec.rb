# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InertiaRails::LiveStream do
  let(:record) { double('Exhibit', to_gid_param: 'gid://dummy/Exhibit/1') }

  describe '.names' do
    it 'joins an array into one stream, like turbo_stream_from' do
      expect(described_class.names([record, :guestbook])).to eq(['inertia:gid://dummy/Exhibit/1:guestbook'])
    end

    it 'takes several streams from `streams:`, each element one stream' do
      expect(described_class.names({ streams: [record, [:user, 7, :alerts]] }))
        .to eq(['inertia:gid://dummy/Exhibit/1', 'inertia:user:7:alerts'])
    end

    it 'refuses values that name no stream' do
      [nil, [], [record, nil], { other: 1 }, { streams: [:feed], other: 1 },
       { streams: [] }, { streams: :feed }].each do |live|
        expect { described_class.names(live) }.to raise_error(ArgumentError), "expected #{live.inspect} to raise"
      end
    end
  end

  describe '.option' do
    it 'refuses positional streams together with `streams:`' do
      expect { described_class.option([:feed], [:other]) }.to raise_error(ArgumentError, /not both/)
    end
  end

  describe 'signing' do
    it 'verifies the names it signs, even when the encoding has url-safe characters and "--"' do
      signed = described_class.signed('inertia:aϾ')

      expect(signed).to start_with('ImluZXJ0aWE6Yc--Ig==--')
      expect(described_class.verified(signed)).to eq('inertia:aϾ')
    end

    it 'rejects tampered, foreign, and missing names' do
      signed = described_class.signed('inertia:feed')
      encoded, digest = signed.split('--')
      forged = "#{Base64.urlsafe_encode64(JSON.dump('inertia:admin'))}--#{digest}"

      expect(described_class.verified(forged)).to be_nil
      expect(described_class.verified("#{encoded}--#{'0' * 64}")).to be_nil
      expect(described_class.verified('inertia:feed')).to be_nil
      expect(described_class.verified('!!--abc')).to be_nil
      expect(described_class.verified(nil)).to be_nil
    end

    it 'rejects signed names without the prefix, like Turbo streams signed with a shared AnyCable secret' do
      expect(described_class.verified(described_class.signed('gid://dummy/Exhibit/1'))).to be_nil
    end

    context 'with AnyCable configured' do
      # Produced by AnyCable::Streams.signed (anycable-core 1.6.4) with streams_secret "test-secret".
      let(:anycable_signed) do
        'ImluZXJ0aWE6Z2lkOi8vZHVtbXkvRXhoaWJpdC8xOmd1ZXN0Ym9vayI=--' \
          '98132cc9189a734c1c5a89720d8367485ae15911d20394bbf047093daca6c8f1'
      end

      before do
        stub_const('AnyCable', Module.new)
        config = Struct.new(:streams_secret).new('test-secret')
        AnyCable.define_singleton_method(:config) { config }
      end

      it 'signs exactly like AnyCable, so anycable-go accepts the names' do
        expect(described_class.signed('inertia:gid://dummy/Exhibit/1:guestbook')).to eq(anycable_signed)
        expect(described_class.verified(anycable_signed)).to eq('inertia:gid://dummy/Exhibit/1:guestbook')
      end
    end
  end
end
