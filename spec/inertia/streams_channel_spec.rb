# frozen_string_literal: true

require 'rails_helper'
require 'action_cable/channel/test_case'

RSpec.describe InertiaRails::StreamsChannel, type: :channel do
  let(:verifier) { ActiveSupport::MessageVerifier.new('test-key', digest: 'SHA256', serializer: JSON) }

  before do
    allow(InertiaRails).to receive(:signed_stream_verifier).and_return(verifier)
  end

  it 'subscribes with a valid signed stream name' do
    signed = InertiaRails::StreamName.signed_stream_name('projects')

    subscribe(signed_stream_name: signed)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from('projects')
  end

  it 'rejects subscription with an invalid signed stream name' do
    subscribe(signed_stream_name: 'tampered-value')

    expect(subscription).to be_rejected
  end

  it 'rejects subscription with nil signed stream name' do
    subscribe(signed_stream_name: nil)

    expect(subscription).to be_rejected
  end

  it 'rejects subscription with no params' do
    subscribe

    expect(subscription).to be_rejected
  end
end
