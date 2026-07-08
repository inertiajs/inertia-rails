# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Live Props integration', type: :request do
  let(:verifier) { ActiveSupport::MessageVerifier.new('test-key', digest: 'SHA256', serializer: JSON) }

  before do
    allow(InertiaRails).to receive(:signed_stream_verifier).and_return(verifier)
  end

  describe 'full round-trip' do
    it 'renders page with rails.streams and the protocol version' do
      get live_props_path, headers: { 'X-Inertia' => true }

      json = JSON.parse(response.body)

      expect(json['component']).to eq('LiveTest')
      expect(json['props']['tasks']).to eq([{ 'id' => 1, 'title' => 'Task 1' }])
      expect(json['rails']['streams']).to be_a(Hash)
      expect(json['rails']['protocol']).to eq(1)

      # Verify the stream token
      signed_name = json['rails']['streams'].keys.first
      expect(verifier.verified(signed_name)).to eq('project')

      # Stream maps to the correct prop
      expect(json['rails']['streams'][signed_name]).to eq({ 'props' => ['tasks'] })
    end

    it 'groups multiple live props on the same stream' do
      get multiple_live_props_path, headers: { 'X-Inertia' => true }

      json = JSON.parse(response.body)
      streams = json['rails']['streams']

      # :project stream has tasks + members
      project_entry = streams.find { |k, _| verifier.verified(k) == 'project' }
      expect(project_entry[1]['props']).to contain_exactly('tasks', 'members')

      # :chat stream has messages
      chat_entry = streams.find { |k, _| verifier.verified(k) == 'chat' }
      expect(chat_entry[1]['props']).to eq(['messages'])
    end

    it 'emits destroy filters for props that opted in via on_destroy' do
      get filtered_live_props_path, headers: { 'X-Inertia' => true }

      json = JSON.parse(response.body)
      entry = json['rails']['streams'].values.first

      expect(entry['props']).to contain_exactly('tasks', 'task_count')
      expect(entry['filters']).to eq([{ 'prop' => 'tasks', 'model' => 'Task' }])
    end

    it 'broadcast_refresh_to sends a bare reload signal' do
      expect(ActionCable.server).to receive(:broadcast).with(
        'project',
        { type: 'reload' }
      )

      InertiaRails.broadcast_refresh_to(:project)
    end

    it 'broadcast_change_to sends a payload-free lifecycle fact' do
      record = double(id: 42, model_name: double(name: 'Task'))

      expect(ActionCable.server).to receive(:broadcast).with(
        'project',
        { type: 'update', model: 'Task', id: 42, request_id: 'test-req-123' }
      )

      InertiaRails.broadcast_change_to(:project, record: record, action: :update, request_id: 'test-req-123')
    end

    it 'broadcast_change_to rejects unknown actions' do
      record = double(id: 1, model_name: double(name: 'Task'))

      expect do
        InertiaRails.broadcast_change_to(:project, record: record, action: :append)
      end.to raise_error(ArgumentError, /Unknown broadcast action/)
    end

    it 'non-live pages have no rails key' do
      get no_live_props_path, headers: { 'X-Inertia' => true }

      json = JSON.parse(response.body)
      expect(json).not_to have_key('rails')
      expect(json['props']['tasks']).to eq([{ 'id' => 1 }])
    end
  end

  describe 'shared live props' do
    around do |example|
      existing_filters = InertiaLiveTestController._process_action_callbacks.map(&:filter)
      InertiaLiveTestController.class_eval do
        inertia_share do
          {
            notifications_count: InertiaRails.live(%i[user notifications]) { 42 },
          }
        end
      end
      example.run
    ensure
      # Remove ONLY the callbacks this block added — skipping every Proc
      # before_action would also nuke InertiaRails::Controller's
      # Current.request assignment for the rest of the suite.
      InertiaLiveTestController._process_action_callbacks.each do |callback|
        next unless callback.kind == :before
        next if existing_filters.include?(callback.filter)

        InertiaLiveTestController.skip_before_action(callback.filter)
      end
    end

    it 'includes shared live props in streams' do
      get no_live_props_path, headers: { 'X-Inertia' => true }

      json = JSON.parse(response.body)
      expect(json['rails']['streams']).to be_a(Hash)

      # Should have the notifications stream
      notif_entry = json['rails']['streams'].find { |k, _| verifier.verified(k) == 'user:notifications' }
      expect(notif_entry).not_to be_nil
      expect(notif_entry[1]['props']).to eq(['notifications_count'])

      # Shared prop value is resolved
      expect(json['props']['notifications_count']).to eq(42)
    end
  end

  describe 'self-exclusion request id' do
    it 'derives live_request_id lazily from the header during a request' do
      get live_request_id_echo_path, headers: { 'X-Inertia-Live-Request-Id' => 'client-req-789' }

      expect(response.body).to eq('client-req-789')
    end

    it 'is empty when the header is absent' do
      get live_request_id_echo_path

      expect(response.body).to eq('')
    end

    it 'rejects malformed header values — the id is echoed into broadcasts' do
      get live_request_id_echo_path, headers: { 'X-Inertia-Live-Request-Id' => 'x' * 100 }
      expect(response.body).to eq('')

      get live_request_id_echo_path, headers: { 'X-Inertia-Live-Request-Id' => 'short' }
      expect(response.body).to eq('')

      get live_request_id_echo_path, headers: { 'X-Inertia-Live-Request-Id' => 'has spaces in it' }
      expect(response.body).to eq('')
    end

    it 'accepts UUIDs and the non-crypto client fallback format' do
      get live_request_id_echo_path,
          headers: { 'X-Inertia-Live-Request-Id' => 'e58e50f4-2b69-45a1-bc99-95f38423fbf6' }
      expect(response.body).to eq('e58e50f4-2b69-45a1-bc99-95f38423fbf6')

      get live_request_id_echo_path, headers: { 'X-Inertia-Live-Request-Id' => 'k2j4h5g6f7-1751892345678' }
      expect(response.body).to eq('k2j4h5g6f7-1751892345678')
    end

    it 'is nil outside of a request' do
      expect(InertiaRails::Current.live_request_id).to be_nil
    end
  end
end
