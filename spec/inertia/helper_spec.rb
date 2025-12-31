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

  describe '#inertia_meta_tags' do
    context 'basic rendering' do
      before do
        controller.instance_variable_set(
          :@_inertia_page,
          {
            props: {
              _inertia_meta: [
                InertiaRails::MetaTag.new(name: 'description', content: 'Inertia rules',
                                          head_key: 'my_key')
              ],
            },
          }
        )
      end

      it 'generates a meta tag' do
        expect(helper.inertia_meta_tags).to eq('<meta name="description" content="Inertia rules" inertia="my_key">')
      end

      context 'with use_data_inertia_head_attribute: true' do
        with_inertia_config use_data_inertia_head_attribute: true

        it 'generates a meta tag with data-inertia attribute' do
          expect(helper.inertia_meta_tags).to eq(
            '<meta name="description" content="Inertia rules" data-inertia="my_key">'
          )
        end
      end
    end

    context 'with multiple meta tags' do
      before do
        controller.instance_variable_set(
          :@_inertia_page,
          {
            props: {
              _inertia_meta: [
                InertiaRails::MetaTag.new(
                  tag_name: 'title', inner_content: 'Inertia Page Title', head_key: 'meta-12345678'
                ),
                InertiaRails::MetaTag.new(
                  name: 'description', content: 'Inertia rules', head_key: 'meta-23456789'
                ),
                InertiaRails::MetaTag.new(
                  tag_name: 'script', type: 'application/ld+json',
                  inner_content: { '@context': 'https://schema.org' }, head_key: 'meta-34567890'
                )
              ],
            },
          }
        )
      end

      it 'generates multiple meta tags' do
        expect(helper.inertia_meta_tags).to include(
          "<title inertia=\"title\">Inertia Page Title</title>\n",
          "<meta name=\"description\" content=\"Inertia rules\" inertia=\"meta-23456789\">\n",
          '<script type="application/ld+json" inertia="meta-34567890">{"@context":"https://schema.org"}</script>'
        )
      end

      context 'with use_data_inertia_head_attribute: true' do
        with_inertia_config use_data_inertia_head_attribute: true

        it 'generates multiple meta tags with data-inertia attribute' do
          expect(helper.inertia_meta_tags).to include(
            "<title data-inertia=\"title\">Inertia Page Title</title>\n",
            "<meta name=\"description\" content=\"Inertia rules\" data-inertia=\"meta-23456789\">\n",
            '<script type="application/ld+json" data-inertia="meta-34567890">{"@context":"https://schema.org"}</script>'
          )
        end
      end
    end
  end
end
