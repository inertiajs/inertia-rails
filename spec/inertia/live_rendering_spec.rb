# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Live props rendering', type: :request do
  let(:verifier) { ActiveSupport::MessageVerifier.new('test-key', digest: 'SHA256', serializer: JSON) }

  before do
    allow(InertiaRails).to receive(:signed_stream_verifier).and_return(verifier)
  end

  context 'with live props' do
    it 'includes rails key with streams in the page JSON' do
      get live_props_path, headers: { 'X-Inertia' => true }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['rails']).to be_a(Hash)
      expect(json['rails']['streams']).to be_a(Hash)
      expect(json['rails']['streams'].size).to eq(1)
      expect(json['rails']).not_to have_key('requestId')
    end

    it 'includes correct props alongside rails metadata' do
      get live_props_path, headers: { 'X-Inertia' => true }

      json = JSON.parse(response.body)
      expect(json['props']['tasks']).to eq([{ 'id' => 1, 'title' => 'Task 1' }])
    end

    it 'maps signed stream names to prop names' do
      get live_props_path, headers: { 'X-Inertia' => true }

      json = JSON.parse(response.body)
      streams = json['rails']['streams']

      signed_name = streams.keys.first
      expect(verifier.verified(signed_name)).to eq('project')
      expect(streams[signed_name]).to eq({ 'props' => ['tasks'] })
    end

    it 'groups multiple props on the same stream' do
      get multiple_live_props_path, headers: { 'X-Inertia' => true }

      json = JSON.parse(response.body)
      streams = json['rails']['streams']

      # Two distinct streams: :project and :chat
      expect(streams.size).to eq(2)

      # Find the :project stream and check it has both props
      project_stream = streams.find { |k, _| verifier.verified(k) == 'project' }
      expect(project_stream).not_to be_nil
      expect(project_stream[1]['props']).to contain_exactly('tasks', 'members')

      # Find the :chat stream
      chat_stream = streams.find { |k, _| verifier.verified(k) == 'chat' }
      expect(chat_stream).not_to be_nil
      expect(chat_stream[1]['props']).to eq(['messages'])
    end
  end

  context 'without live props' do
    it 'does not include the rails key' do
      get no_live_props_path, headers: { 'X-Inertia' => true }

      json = JSON.parse(response.body)
      expect(json).not_to have_key('rails')
    end
  end

  context 'on initial HTML response (non-Inertia visit)' do
    it 'includes rails metadata in the data-page attribute' do
      get live_props_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-page=')

      # Extract the JSON from the data-page attribute
      match = response.body.match(/data-page="([^"]*)"/)
      expect(match).not_to be_nil

      page_json = JSON.parse(CGI.unescapeHTML(match[1]))
      expect(page_json['rails']).to be_a(Hash)
      expect(page_json['rails']['streams']).to be_a(Hash)
    end
  end
end
