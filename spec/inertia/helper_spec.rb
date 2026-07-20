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

  describe '#inertia_root' do
    let(:page) do
      {
        component: 'TestComponent',
        props: { message: 'Hello' },
        url: '/test',
        version: nil,
      }
    end

    def stub_content_security_policy_nonce(value)
      helper.singleton_class.define_method(:content_security_policy_nonce) { value }
    end

    context 'when using a script element for the initial page' do
      with_inertia_config use_script_element_for_initial_page: true

      it 'renders the script tag with the Rails CSP nonce' do
        stub_content_security_policy_nonce('test-nonce')

        expect(helper.inertia_root(page: page)).to include(
          '<script data-page="app" type="application/json" nonce="test-nonce">'
        )
      end

      it 'does not render a nonce attribute when Rails does not provide a nonce' do
        stub_content_security_policy_nonce(nil)

        expect(helper.inertia_root(page: page)).not_to include(' nonce=')
      end
    end

    context 'when using a data-page attribute for the initial page' do
      with_inertia_config use_script_element_for_initial_page: false

      it 'preserves the existing non-script rendering' do
        stub_content_security_policy_nonce('test-nonce')

        result = helper.inertia_root(page: page)

        expect(result).to include('<div id="app" data-page=')
        expect(result).not_to include('<script')
        expect(result).not_to include(' nonce=')
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

    context 'with server_head serialization (HTML strings in the head prop)' do
      with_inertia_config server_head: true

      before do
        controller.instance_variable_set(
          :@_inertia_page,
          {
            props: {
              head: [
                '<meta name="description" content="Inertia rules" data-inertia="my_key">'.html_safe,
                '<title data-inertia="title">Inertia Page Title</title>'.html_safe
              ],
            },
          }
        )
      end

      it 'renders the strings as-is' do
        expect(helper.inertia_meta_tags).to eq(
          "<meta name=\"description\" content=\"Inertia rules\" data-inertia=\"my_key\">\n" \
          '<title data-inertia="title">Inertia Page Title</title>'
        )
      end

      it 'returns html_safe output' do
        expect(helper.inertia_meta_tags).to be_html_safe
      end

      context 'with a custom prop name' do
        with_inertia_config server_head: 'custom_meta'

        before do
          controller.instance_variable_set(
            :@_inertia_page,
            { props: { custom_meta: ['<title data-inertia="title">Custom</title>'.html_safe] } }
          )
        end

        it 'reads the configured prop' do
          expect(helper.inertia_meta_tags).to eq('<title data-inertia="title">Custom</title>')
        end
      end
    end

    context 'with plain strings in the structured prop' do
      before do
        controller.instance_variable_set(
          :@_inertia_page,
          { props: { _inertia_meta: ['<script>alert("XSS")</script>'] } }
        )
      end

      it 'escapes them' do
        expect(helper.inertia_meta_tags).to eq('&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;')
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
