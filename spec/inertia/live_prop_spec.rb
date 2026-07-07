# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InertiaRails::LiveProp do
  it_behaves_like 'base prop' do
    let(:prop_options) { { streamable: :stream_name } }
    let(:prop) { described_class.new(**prop_options) { 'block' } }
  end

  describe '#live?' do
    let(:prop) { described_class.new(streamable: :project) { 'data' } }

    it { expect(prop.live?).to be true }
  end

  describe '#streamable' do
    let(:prop) { described_class.new(streamable: :project) { 'data' } }

    it { expect(prop.streamable).to eq(:project) }

    it 'is required' do
      expect { described_class.new { 'data' } }.to raise_error(ArgumentError)
    end

    context 'with an array streamable' do
      let(:prop) { described_class.new(streamable: [:project, :tasks]) { 'data' } }

      it { expect(prop.streamable).to eq([:project, :tasks]) }
    end
  end

  describe '#destroy_filter_model' do
    it 'is nil by default (destroys reload through the controller)' do
      prop = described_class.new(streamable: :project) { 'data' }
      expect(prop.destroy_filter_model).to be_nil
    end

    it 'accepts a model name string' do
      prop = described_class.new(streamable: :project, on_destroy: 'Task') { 'data' }
      expect(prop.destroy_filter_model).to eq('Task')
    end

    it 'accepts a class and uses its name' do
      klass = Class.new { def self.name = 'Task' }
      prop = described_class.new(streamable: :project, on_destroy: klass) { 'data' }
      expect(prop.destroy_filter_model).to eq('Task')
    end
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
