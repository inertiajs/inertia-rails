# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Live Props integration', type: :request do
  let(:verifier) { ActiveSupport::MessageVerifier.new('test-key', digest: 'SHA256', serializer: JSON) }

  before do
    allow(InertiaRails).to receive(:signed_stream_verifier).and_return(verifier)
  end

  describe 'full round-trip' do
    it 'renders page with rails.streams' do
      get live_props_path, headers: { 'X-Inertia' => true }

      json = JSON.parse(response.body)

      expect(json['component']).to eq('LiveTest')
      expect(json['props']['tasks']).to eq([{ 'id' => 1, 'title' => 'Task 1' }])
      expect(json['rails']['streams']).to be_a(Hash)
      expect(json['rails']).not_to have_key('requestId')

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

    it 'broadcast_to sends to the correct ActionCable stream' do
      expect(ActionCable.server).to receive(:broadcast).with(
        'project',
        { type: 'reload' }
      )

      InertiaRails.broadcast_to(:project)
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
      InertiaLiveTestController.class_eval do
        inertia_share do
          {
            notifications_count: InertiaRails.live([:user, :notifications]) { 42 },
          }
        end
      end
      example.run
    ensure
      # Clean up shared data by removing the before_action
      InertiaLiveTestController._process_action_callbacks.each do |callback|
        if callback.kind == :before && callback.filter.is_a?(Proc)
          InertiaLiveTestController.skip_before_action(callback.filter) rescue nil
        end
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

  describe 'self-exclusion via client header' do
    it 'reads live_request_id from X-Inertia-Live-Request-Id header' do
      captured_id = nil
      allow(InertiaRails::Current).to receive(:live_request_id=).and_wrap_original do |m, val|
        captured_id = val
        m.call(val)
      end

      get live_props_path, headers: { 'X-Inertia' => true, 'X-Inertia-Live-Request-Id' => 'client-req-789' }

      expect(captured_id).to eq('client-req-789')
    end

    it 'live_request_id is nil when header is absent' do
      captured_id = :not_set
      allow(InertiaRails::Current).to receive(:live_request_id=).and_wrap_original do |m, val|
        captured_id = val
        m.call(val)
      end

      get live_props_path, headers: { 'X-Inertia' => true }

      expect(captured_id).to be_nil
    end

    it 'broadcasts include the request_id from the client header' do
      expect(ActionCable.server).to receive(:broadcast).with(
        'project',
        hash_including(request_id: 'test-req-123')
      )

      InertiaRails.broadcast_action_to(:project, record: double(id: 1, as_json: { 'id' => 1 }), action: :append, request_id: 'test-req-123')
    end

    it 'broadcastable concern passes Current.live_request_id automatically' do
      InertiaRails::Current.live_request_id = 'client-req-456'

      expect(ActionCable.server).to receive(:broadcast).with(
        anything,
        hash_including(request_id: 'client-req-456')
      )

      InertiaRails.broadcast_action_to(:project, record: double(id: 1, as_json: { 'id' => 1 }), action: :append, request_id: InertiaRails::Current.live_request_id)
    end
  end
end
