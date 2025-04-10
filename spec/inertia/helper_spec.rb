# frozen_string_literal: true

RSpec.describe InertiaRails::Helper do
  let(:controller) { ApplicationController.new }

  let(:test_helper) do
    Class.new do
      include InertiaRails::Helper
      attr_accessor :controller
    end.new
  end

  before do
    test_helper.controller = controller
  end

  describe '#inertia_rendering?' do
    context 'when not rendering through Inertia' do
      it 'returns nil' do
        expect(test_helper.inertia_rendering?).to be_nil
      end
    end

    context 'when rendering through Inertia' do
      before do
        controller.instance_variable_set('@_inertia_rendering', true)
      end

      it 'returns true' do
        expect(test_helper.inertia_rendering?).to be true
      end
    end
  end
end
