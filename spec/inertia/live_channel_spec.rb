# frozen_string_literal: true

require 'rails_helper'
require 'action_cable'

RSpec.describe 'InertiaRails::LiveChannel' do
  let(:channel_class) { Class.new(ActionCable::Channel::Base) { include InertiaRails::LiveChannel } }

  it 'provides the subscription behavior as a mixin' do
    expect(InertiaRails::LiveChannel).to be_an_instance_of(Module)
  end

  # Rails 8.2 replaced Action Cable's channel test stubs, so the spec brings its own connection.
  def subscribe(stream)
    connection = double('connection', identifiers: [])
    channel = channel_class.new(connection, 'id', { stream: stream }.with_indifferent_access)
    allow(channel).to receive(:stream_from)
    allow(channel).to receive(:reject)
    channel.send(:subscribed)
    channel
  end

  it 'streams from the name a signed stream carries' do
    channel = subscribe(InertiaRails::LiveStream.signed('inertia:feed'))

    expect(channel).to have_received(:stream_from).with('inertia:feed')
    expect(channel).not_to have_received(:reject)
  end

  it 'rejects a stream it did not sign' do
    channel = subscribe('inertia:feed')

    expect(channel).to have_received(:reject)
    expect(channel).not_to have_received(:stream_from)
  end
end
