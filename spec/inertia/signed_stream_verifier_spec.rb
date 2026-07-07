# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'InertiaRails.signed_stream_verifier_key' do
  around do |example|
    original_key = InertiaRails.instance_variable_get(:@signed_stream_verifier_key)
    original_verifier = InertiaRails.instance_variable_get(:@signed_stream_verifier)
    example.run
  ensure
    InertiaRails.instance_variable_set(:@signed_stream_verifier_key, original_key)
    InertiaRails.instance_variable_set(:@signed_stream_verifier, original_verifier)
  end

  it 'derives the key lazily from the application key generator' do
    InertiaRails.instance_variable_set(:@signed_stream_verifier_key, nil)

    expect(InertiaRails.signed_stream_verifier_key).to eq(
      Rails.application.key_generator.generate_key('inertia_rails/signed_stream_verifier_key')
    )
  end

  it 'honors a user-provided override' do
    InertiaRails.signed_stream_verifier_key = 'user-provided-key'
    InertiaRails.instance_variable_set(:@signed_stream_verifier, nil) # force rebuild

    signed = InertiaRails.signed_stream_verifier.generate('my_stream')

    # A verifier built with a different key must reject it.
    other = ActiveSupport::MessageVerifier.new('some-other-key', digest: 'SHA256', serializer: JSON)
    expect(other.verified(signed)).to be_nil

    # A verifier built with the same key must accept it.
    same = ActiveSupport::MessageVerifier.new('user-provided-key', digest: 'SHA256', serializer: JSON)
    expect(same.verified(signed)).to eq('my_stream')
  end

  it 'signs and verifies round-trip with the lazy default' do
    InertiaRails.instance_variable_set(:@signed_stream_verifier_key, nil)
    InertiaRails.instance_variable_set(:@signed_stream_verifier, nil)

    signed = InertiaRails.signed_stream_verifier.generate('project')
    expect(InertiaRails.signed_stream_verifier.verified(signed)).to eq('project')
  end
end
