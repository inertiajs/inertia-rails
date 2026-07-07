# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'InertiaRails broadcasting' do
  let(:verifier) { ActiveSupport::MessageVerifier.new('test-key', digest: 'SHA256', serializer: JSON) }

  before do
    allow(InertiaRails).to receive(:signed_stream_verifier).and_return(verifier)
  end

  describe '.broadcast_refresh_to' do
    it 'broadcasts a reload message' do
      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'reload' }
      )

      InertiaRails.broadcast_refresh_to(:projects)
    end

    it 'includes request_id when provided' do
      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'reload', request_id: 'abc-123' }
      )

      InertiaRails.broadcast_refresh_to(:projects, request_id: 'abc-123')
    end
  end

  describe '.broadcast_action_to' do
    it 'broadcasts an append signal with serialized record using serializer: lambda' do
      record = double(id: 42)
      serializer = ->(r) { { id: r.id, custom: true } }

      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'append', value: { id: 42, custom: true }, id: 42 }
      )

      InertiaRails.broadcast_action_to(:projects, record: record, action: :append, serializer: serializer)
    end

    it 'broadcasts a replace signal' do
      record = double(id: 42)
      serializer = ->(r) { { id: r.id, name: 'updated' } }

      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'update', value: { id: 42, name: 'updated' }, id: 42 }
      )

      InertiaRails.broadcast_action_to(:projects, record: record, action: :replace, serializer: serializer)
    end

    it 'broadcasts a prepend signal' do
      record = double(id: 42)
      serializer = ->(r) { { id: r.id, name: 'new' } }

      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'prepend', value: { id: 42, name: 'new' }, id: 42 }
      )

      InertiaRails.broadcast_action_to(:projects, record: record, action: :prepend, serializer: serializer)
    end

    it 'broadcasts a destroy signal without serialization' do
      record = double(id: 42)

      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'destroy', id: 42 }
      )

      InertiaRails.broadcast_action_to(:projects, record: record, action: :remove)
    end

    it 'uses as_json when no serializer provided' do
      record = double(id: 42, as_json: { 'id' => 42, 'name' => 'test' })

      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'append', value: { 'id' => 42, 'name' => 'test' }, id: 42 }
      )

      InertiaRails.broadcast_action_to(:projects, record: record, action: :append)
    end

    it 'uses broadcast_serializer config when no explicit serializer provided' do
      record = double(id: 42)
      InertiaRails.configure do |config|
        config.broadcast_serializer = ->(r) { { id: r.id, from_config: true } }
      end

      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'append', value: { id: 42, from_config: true }, id: 42 }
      )

      InertiaRails.broadcast_action_to(:projects, record: record, action: :append)
    ensure
      InertiaRails.configure { |config| config.broadcast_serializer = nil }
    end

    it 'prefers explicit serializer over broadcast_serializer config' do
      record = double(id: 42)
      InertiaRails.configure do |config|
        config.broadcast_serializer = ->(r) { { from_config: true } }
      end
      explicit = ->(r) { { id: r.id, explicit: true } }

      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'append', value: { id: 42, explicit: true }, id: 42 }
      )

      InertiaRails.broadcast_action_to(:projects, record: record, action: :append, serializer: explicit)
    ensure
      InertiaRails.configure { |config| config.broadcast_serializer = nil }
    end

    it 'uses resource class .to_h when serializer is a Class' do
      record = double(id: 42)
      resource_class = Class.new do
        def initialize(record)
          @record = record
        end

        def to_h
          { id: @record.id, title: 'Task' }
        end
      end

      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'append', value: { id: 42, title: 'Task' }, id: 42 }
      )

      InertiaRails.broadcast_action_to(:projects, record: record, action: :append, serializer: resource_class)
    end

    it 'includes request_id when provided' do
      record = double(id: 42, as_json: { 'id' => 42 })

      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'append', value: { 'id' => 42 }, id: 42, request_id: 'req-1' }
      )

      InertiaRails.broadcast_action_to(:projects, record: record, action: :append, request_id: 'req-1')
    end

    it 'resolves array streamables' do
      record = double(id: 42, as_json: { 'id' => 42 })

      expect(ActionCable.server).to receive(:broadcast).with(
        'projects:tasks',
        hash_including(type: 'append')
      )

      InertiaRails.broadcast_action_to([:projects, :tasks], record: record, action: :append)
    end
  end

  describe '.broadcast_to (convenience)' do
    it 'broadcasts a reload message by default' do
      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'reload' }
      )

      InertiaRails.broadcast_to(:projects)
    end

    it 'routes to broadcast_action_to when record and action provided' do
      record = double(id: 42, as_json: { 'id' => 42 })

      expect(InertiaRails).to receive(:broadcast_action_to).with(
        :projects,
        record: record,
        action: :append
      )

      InertiaRails.broadcast_to(:projects, record: record, action: :append)
    end
  end
end
