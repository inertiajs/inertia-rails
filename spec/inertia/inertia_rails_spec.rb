RSpec.describe InertiaRails do
  describe ".lazy" do
    let(:deprecator) do
      double(warn: nil).tap do |deprecator|
        allow(InertiaRails).to receive(:deprecator).and_return(deprecator)
      end
    end

    it "is deprecated" do
      expect(deprecator).to receive(:warn).with("`lazy` is deprecated and will be removed in InertiaRails 4.0, use `optional` instead.")
      expect(InertiaRails.lazy).to be_a(InertiaRails::OptionalProp)
    end
  end
end
