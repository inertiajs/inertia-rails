# frozen_string_literal: true

RSpec.shared_examples 'base prop' do
  describe '#call' do
    subject(:call) { prop.call(controller) }
    let(:prop) { described_class.new { 'block' } }
    let(:headers) { {} }
    let(:controller) do
      controller = ApplicationController.new
      request = double('Request')

      allow(controller).to receive(:request).and_return(request)
      allow(request).to receive(:headers).and_return(headers)
      controller
    end

    it { is_expected.to eq('block') }

    context 'with dependency on the context of a controller' do
      let(:prop) { described_class.new { controller_method } }

      it { is_expected.to eq('controller_method value') }
    end
  end
end
