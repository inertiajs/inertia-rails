# frozen_string_literal: true

RSpec.describe InertiaRails::ActionFilter do
  let(:controller) do
    instance_double(
      'ActionController::Base',
      action_name: 'current_action',
      class: instance_double('Class', name: 'TestController')
    ).tap do |stub|
      allow(stub).to receive(:available_action?).and_return(true)
      allow(stub).to receive(:available_action?).with('nonexistent').and_return(false)
    end
  end

  describe '#match?' do
    context 'when action exists' do
      it 'returns true if action matches' do
        filter = described_class.new(:only, 'current_action')
        expect(filter.match?(controller)).to be true
      end

      it 'returns false if action does not match' do
        filter = described_class.new(:only, 'other_action')
        expect(filter.match?(controller)).to be false
      end

      it 'handles multiple actions' do
        filter = described_class.new(:only, %w[current_action other actions])
        expect(filter.match?(controller)).to be true
      end

      it 'handles symbol actions' do
        filter = described_class.new(:only, :current_action)
        expect(filter.match?(controller)).to be true
      end
    end

    context 'when action does not exist' do
      it 'raises ActionNotFound with appropriate message' do
        filter = described_class.new(:only, :nonexistent)
        expected_message = <<~MSG
          The nonexistent action could not be found for the :inertia_share
          callback on TestController, but it is listed in the controller's
          :only option.
        MSG

        expect do
          filter.match?(controller)
        end.to raise_error(AbstractController::ActionNotFound, expected_message)
      end
    end
  end
end
