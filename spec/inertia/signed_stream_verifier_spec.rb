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

  it 'raises a clear error when the key has not been configured' do
    InertiaRails.instance_variable_set(:@signed_stream_verifier_key, nil)

    expect { InertiaRails.signed_stream_verifier_key }
      .to raise_error(ArgumentError, /signed_stream_verifier_key/)
  end

  it 'honors a user-provided override (config.inertia_rails.signed_stream_verifier_key)' do
    # Simulate what the engine initializer does when config.inertia_rails.signed_stream_verifier_key
    # is set by the host app.
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

  it 'falls back to Rails.application.key_generator when no override is provided' do
    # This exercises the path that the engine initializer uses by default.
    InertiaRails.signed_stream_verifier_key =
      Rails.application.key_generator.generate_key('inertia_rails/signed_stream_verifier_key')
    InertiaRails.instance_variable_set(:@signed_stream_verifier, nil)

    expect { InertiaRails.signed_stream_verifier.generate('x') }.not_to raise_error
  end
end
