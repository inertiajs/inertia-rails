# frozen_string_literal: true

require 'rails_helper'
require 'inertia_rails/testing/live_contracts'

RSpec.describe InertiaRails::Testing::LiveContracts do
  let(:committed) { File.expand_path('../fixtures/contracts/v1.json', __dir__) }

  # The client repo (inertia-rails/client) vendors this exact file at
  # packages/core/__tests__/contracts/v1.json and replays it through the real
  # StreamSubscriber. Regenerate with: rake inertia_rails:live:contracts
  it 'matches the committed fixture byte-for-byte' do
    expect(described_class.to_json_file).to eq(File.read(committed))
  end
end
