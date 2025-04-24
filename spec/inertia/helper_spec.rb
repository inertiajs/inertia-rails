# frozen_string_literal: true

RSpec.describe InertiaRails::Helper, type: :helper do
  describe '#inertia_rendering?' do
    context 'when not rendering through Inertia' do
      it 'returns nil' do
        expect(helper.inertia_rendering?).to be_nil
      end
    end

    context 'when rendering through Inertia' do
      before do
        controller.instance_variable_set('@_inertia_rendering', true)
      end

      it 'returns true' do
        expect(helper.inertia_rendering?).to be true
      end
    end
  end

  describe "#inertia_meta_tags" do
    context 'basic rendering' do
      before do
        allow(helper).to receive(:local_assigns).and_return({
          page: {
            meta: [
              InertiaRails::MetaTag.new(name: 'description', content: 'Inertia rules', head_key: "my_key")
            ]
          }
        })
      end

      it "generates a meta tag" do
        expect(helper.inertia_meta_tags).to eq('<meta name="description" content="Inertia rules" inertia="my_key">')
      end
    end

    context "with multiple meta tags" do
      before do
        allow(helper).to receive(:local_assigns).and_return({
          page: {
            meta: [
              InertiaRails::MetaTag.new(tag_name: 'title', content: 'Inertia Page Title', head_key: "meta-12345678"),
              InertiaRails::MetaTag.new(name: 'description', content: 'Inertia rules', head_key: "meta-23456789"),
              InertiaRails::MetaTag.new(tag_name: 'script', type: "application/ld+json", content: { '@context': 'https://schema.org' }, head_key: "meta-34567890"),
            ]
          }
        })
      end

      it "generates multiple meta tags" do
        expect(helper.inertia_meta_tags).to include("<title inertia=\"meta-12345678\">Inertia Page Title</title>\n")
        expect(helper.inertia_meta_tags).to include("<meta name=\"description\" content=\"Inertia rules\" inertia=\"meta-23456789\">\n")
        expect(helper.inertia_meta_tags).to include("<script type=\"application/ld+json\" inertia=\"meta-34567890\">{\"@context\":\"https://schema.org\"}</script>")
      end
    end
  end
end
