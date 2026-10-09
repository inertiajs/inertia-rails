# frozen_string_literal: true

require 'rails_helper'
require 'action_cable'
require 'action_cable/channel/test_case'

RSpec.describe 'InertiaRails::LiveChannel' do
  def subscribe(params)
    channel = InertiaRails::LiveChannel.new(ActionCable::Channel::ConnectionStub.new, 'id',
                                            params.with_indifferent_access)
    channel.extend(ActionCable::Channel::ChannelStub)
    channel.subscribe_to_channel
    channel
  end

  it 'streams from the name a signed stream carries' do
    channel = subscribe('stream' => InertiaRails::LiveStream.signed('inertia:feed'))

    expect(channel).to be_confirmed
    expect(channel.streams).to eq(['inertia:feed'])
  end

  it 'rejects a stream it did not sign' do
    channel = subscribe('stream' => 'inertia:feed')

    expect(channel).to be_rejected
    expect(channel.streams).to be_empty
  end
end
