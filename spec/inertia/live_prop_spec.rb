# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InertiaRails::LiveProp do
  it_behaves_like 'base prop' do
    let(:prop) { described_class.new(streamable: :stream_name) { 'block' } }
  end

  describe '#live?' do
    let(:prop) { described_class.new(streamable: :project) { 'data' } }

    it { expect(prop.live?).to be true }
  end

  describe '#streamable' do
    let(:prop) { described_class.new(streamable: :project) { 'data' } }

    it { expect(prop.streamable).to eq(:project) }

    context 'with an array streamable' do
      let(:prop) { described_class.new(streamable: [:project, :tasks]) { 'data' } }

      it { expect(prop.streamable).to eq([:project, :tasks]) }
    end
  end

  describe '#deferred?' do
    let(:prop) { described_class.new(streamable: :project) { 'data' } }

    it { expect(prop.deferred?).to be false }
  end

  describe '#merge?' do
    let(:prop) { described_class.new(streamable: :project) { 'data' } }

    it { expect(prop.merge?).to be false }

    context 'when merge is set' do
      let(:prop) { described_class.new(streamable: :project, merge: true) { 'data' } }

      it { expect(prop.merge?).to be true }
    end

    context 'when merge with match_on is set' do
      let(:prop) { described_class.new(streamable: :project, merge: true, match_on: 'id') { 'data' } }

      it { expect(prop.merge?).to be true }
      it { expect(prop.match_on).to eq(['id']) }
    end
  end

  describe '#once?' do
    let(:prop) { described_class.new(streamable: :project) { 'data' } }

    it { expect(prop.once?).to be false }

    context 'when once is set' do
      let(:prop) { described_class.new(streamable: :project, once: true) { 'data' } }

      it { expect(prop.once?).to be true }
    end
  end
end
