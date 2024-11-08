RSpec.describe InertiaRails::LazyProp do
  it_behaves_like 'base prop'

  describe '#call' do
    subject(:call) { prop.call(controller) }
    let(:prop) { described_class.new('value') }
    let(:controller) { ApplicationController.new }

    it { is_expected.to eq('value') }

    context 'with false as value' do
      let(:prop) { described_class.new(false) }

      it { is_expected.to eq(false) }
    end

    context 'with nil as value' do
      let(:prop) { described_class.new(nil) }

      it { is_expected.to eq(nil) }
    end

    context 'with a callable value' do
      let(:prop) { described_class.new(-> { 'callable' }) }

      it { is_expected.to eq('callable') }

      context 'with dependency on the context of a controller' do
        let(:prop) { described_class.new(-> { controller_method }) }

        it { is_expected.to eq('controller_method value') }
      end
    end
  end
end
