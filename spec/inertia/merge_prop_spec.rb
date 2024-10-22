RSpec.describe InertiaRails::MergeProp do
  let(:prop) { described_class.new('value') }

  describe '#merge?' do
    subject { prop.merge? }

    it { is_expected.to be(true) }
  end

  it_behaves_like 'callable prop'
end
