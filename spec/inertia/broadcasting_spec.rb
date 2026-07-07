# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'InertiaRails broadcasting' do
  describe '.broadcast_refresh_to' do
    it 'broadcasts a bare reload message' do
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

    it 'resolves compound streamables to the joined stream name' do
      expect(ActionCable.server).to receive(:broadcast).with(
        'projects:tasks',
        { type: 'reload' }
      )

      InertiaRails.broadcast_refresh_to([:projects, :tasks])
    end
  end

  describe '.broadcast_change_to' do
    let(:record) { double(id: 42, model_name: double(name: 'Task')) }

    it 'broadcasts a payload-free lifecycle fact for each action' do
      InertiaRails::Broadcast::ACTIONS.each do |action|
        expect(ActionCable.server).to receive(:broadcast).with(
          'projects',
          { type: action.to_s, model: 'Task', id: 42 }
        )

        InertiaRails.broadcast_change_to(:projects, record: record, action: action)
      end
    end

    it 'includes request_id when provided' do
      expect(ActionCable.server).to receive(:broadcast).with(
        'projects',
        { type: 'create', model: 'Task', id: 42, request_id: 'req-9' }
      )

      InertiaRails.broadcast_change_to(:projects, record: record, action: :create, request_id: 'req-9')
    end

    it 'never includes a value payload — signals are facts, not data' do
      expect(ActionCable.server).to receive(:broadcast) do |_stream, message|
        expect(message.keys).to contain_exactly(:type, :model, :id)
      end

      InertiaRails.broadcast_change_to(:projects, record: record, action: :update)
    end

    it 'rejects unknown actions loudly' do
      expect do
        InertiaRails.broadcast_change_to(:projects, record: record, action: :append)
      end.to raise_error(ArgumentError, /Unknown broadcast action :append/)
    end
  end

  describe 'stream name resolution' do
    it 'uses gid params for records' do
      gid_record = double(to_gid_param: 'gid://app/Project/1')

      expect(ActionCable.server).to receive(:broadcast).with(
        'gid://app/Project/1',
        { type: 'reload' }
      )

      InertiaRails.broadcast_refresh_to(gid_record)
    end
  end
end
