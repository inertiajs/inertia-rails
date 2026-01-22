# frozen_string_literal: true

RSpec.describe InertiaRails::MetaTag do
  let(:meta_tag) { described_class.new(head_key: dummy_head_key, name: 'description', content: 'Inertia rules') }
  let(:dummy_head_key) { 'meta-12345678' }
  let(:tag_helper) { ActionController::Base.helpers.tag }

  describe '#to_json' do
    it 'returns the meta tag as JSON' do
      expected_json = {
        tagName: :meta,
        headKey: dummy_head_key,
        name: 'description',
        content: 'Inertia rules',
      }.to_json

      expect(meta_tag.to_json).to eq(expected_json)
    end

    it 'transforms snake_case keys to camelCase' do
      meta_tag = described_class.new(head_key: dummy_head_key, http_equiv: 'content-security-policy',
                                     content: "default-src 'self'")

      expected_json = {
        tagName: :meta,
        headKey: dummy_head_key,
        httpEquiv: 'content-security-policy',
        content: "default-src 'self'",
      }.to_json

      expect(meta_tag.to_json).to eq(expected_json)
    end

    it 'handles JSON LD content' do
      meta_tag = described_class.new(tag_name: 'script', head_key: dummy_head_key, type: 'application/ld+json',
                                     inner_content: { '@context': 'https://schema.org' })

      expected_json = {
        tagName: :script,
        headKey: dummy_head_key,
        type: 'application/ld+json',
        innerContent: { '@context': 'https://schema.org' },
      }.to_json

      expect(meta_tag.to_json).to eq(expected_json)
    end

    it 'marks executable script tags with text/plain' do
      meta_tag = described_class.new(tag_name: 'script', head_key: dummy_head_key,
                                     inner_content: '<script>alert("XSS")</script>', type: 'application/javascript')

      expected_json = {
        tagName: :script,
        headKey: dummy_head_key,
        type: 'text/plain',
        innerContent: '<script>alert("XSS")</script>',
      }.to_json

      expect(meta_tag.to_json).to eq(expected_json)
    end
  end

  describe 'generated head keys' do
    it 'generates a headKey of the format {tag name}-{hexdigest of tag content}' do
      meta_tag = described_class.new(some_name: 'description', content: 'Inertia rules')
      expected_head_key = "meta-#{Digest::MD5.hexdigest('content=Inertia rules&some_name=description')[0, 8]}"

      expect(meta_tag.as_json[:headKey]).to eq(expected_head_key)
    end

    it 'generates the same headKey regardless of hash data order' do
      first_tags = described_class.new(some_name: 'description', content: 'Inertia rules').as_json
      first_head_key = first_tags[:headKey]

      second_tags = described_class.new(content: 'Inertia rules', some_name: 'description').as_json
      second_head_key = second_tags[:headKey]

      expect(first_head_key).to eq(second_head_key)
    end

    it 'generates a different headKey for different content' do
      first_tags = described_class.new(some_name: 'thing', content: 'Inertia rules').as_json
      first_head_key = first_tags[:headKey]

      second_tags = described_class.new(some_name: 'thing', content: 'Inertia rocks').as_json
      second_head_key = second_tags[:headKey]

      expect(first_head_key).not_to eq(second_head_key)
    end

    it 'respects a user specified head_key' do
      custom_head_key = 'blah'
      meta_tag = described_class.new(head_key: custom_head_key, name: 'description', content: 'Inertia rules')

      expect(meta_tag.as_json[:headKey]).to eq(custom_head_key)
    end

    it 'generates a head key by the name attribute if no head_key is provided' do
      meta_tag = described_class.new(name: 'description', content: 'Inertia rules')

      expect(meta_tag.as_json[:headKey]).to eq('meta-name-description')
    end

    it 'generates a head key by the http_equiv attribute if no head_key is provided' do
      meta_tag = described_class.new(http_equiv: 'content-security-policy', content: "default-src 'self'")

      expect(meta_tag.as_json[:headKey]).to eq('meta-http_equiv-content-security-policy')
    end

    it 'generates a head key by the property attribute if no head_key is provided' do
      meta_tag = described_class.new(property: 'og:title', content: 'Inertia Rocks')

      expect(meta_tag.as_json[:headKey]).to eq('meta-property-og-title')
    end

    context 'with allow_duplicates set to true' do
      it 'generates a head key with a unique suffix' do
        meta_tag = described_class.new(name: 'description', content: 'Inertia rules', allow_duplicates: true)
        expected_hash = Digest::MD5.hexdigest('content=Inertia rules&name=description')[0, 8]

        expect(meta_tag.as_json[:headKey]).to eq("meta-name-description-#{expected_hash}")
      end
    end
  end

  describe '#to_tag' do
    it 'returns a string meta tag' do
      tag = meta_tag.to_tag(tag_helper)
      expect(tag).to be_a(String)
      expect(tag).to eq('<meta name="description" content="Inertia rules" inertia="meta-12345678">')
    end

    it 'renders kebab case' do
      meta_tag = described_class.new(tag_name: :meta, head_key: dummy_head_key, http_equiv: 'X-UA-Compatible',
                                     content: 'IE=edge')

      tag = meta_tag.to_tag(tag_helper)

      expect(tag).to eq('<meta http-equiv="X-UA-Compatible" content="IE=edge" inertia="meta-12345678">')
    end

    context 'with use_data_inertia_head_attribute set to true' do
      with_inertia_config use_data_inertia_head_attribute: true

      it 'returns a string meta tag' do
        tag = meta_tag.to_tag(tag_helper)
        expect(tag).to be_a(String)
        expect(tag).to eq('<meta name="description" content="Inertia rules" data-inertia="meta-12345678">')
      end

      it 'renders kebab case' do
        meta_tag = described_class.new(tag_name: :meta, head_key: dummy_head_key, http_equiv: 'X-UA-Compatible',
                                       content: 'IE=edge')

        tag = meta_tag.to_tag(tag_helper)

        expect(tag).to eq('<meta http-equiv="X-UA-Compatible" content="IE=edge" data-inertia="meta-12345678">')
      end
    end

    describe 'script tag rendering' do
      it 'renders JSON LD content correctly' do
        meta_tag = described_class.new(tag_name: :script, head_key: dummy_head_key, type: 'application/ld+json',
                                       inner_content: { '@context': 'https://schema.org' })

        tag = meta_tag.to_tag(tag_helper)

        expect(tag).to eq('<script type="application/ld+json" inertia="meta-12345678">{"@context":"https://schema.org"}</script>')
      end

      it 'adds text/plain and escapes all other script tags' do
        meta_tag = described_class.new(tag_name: :script, head_key: dummy_head_key, type: 'application/javascript',
                                       inner_content: 'alert("XSS")')

        tag = meta_tag.to_tag(tag_helper)

        expect(tag).to eq('<script type="text/plain" inertia="meta-12345678">alert(&quot;XSS&quot;)</script>')
      end
    end

    describe 'rendering unary tags' do
      described_class::UNARY_TAGS.each do |tag_name|
        it "renders a content attribute for a #{tag_name} tag" do
          meta_tag = described_class.new(tag_name: tag_name, head_key: dummy_head_key, content: 'Inertia rules')

          tag = meta_tag.to_tag(tag_helper)

          expect(tag).to include("<#{tag_name} content=\"Inertia rules\" inertia=\"meta-12345678\">")
        end
      end
    end

    it 'escapes inner content for non-script tags' do
      meta_tag = described_class.new(tag_name: :div, head_key: dummy_head_key,
                                     inner_content: '<script>alert("XSS")</script>')

      tag = meta_tag.to_tag(tag_helper)

      expect(tag).to eq('<div inertia="meta-12345678">&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;</div>')
    end
  end

  describe 'title tag rendering' do
    it 'renders a title tag if only a title key is provided' do
      meta_tag = described_class.new(tag_name: :title, head_key: dummy_head_key, inner_content: 'Inertia Page Title')

      tag = meta_tag.to_tag(ActionController::Base.helpers.tag)

      expect(tag).to eq('<title inertia="title">Inertia Page Title</title>')
    end

    context 'when only a title key is provided' do
      let(:title_tag) { described_class.new(title: 'Inertia Is Great', head_key: 'title') }

      it 'renders JSON correctly' do
        expect(title_tag.to_json).to eq({
          tagName: :title,
          headKey: 'title',
          innerContent: 'Inertia Is Great',
        }.to_json)
      end

      it 'renders a title tag' do
        expect(title_tag.to_tag(tag_helper)).to eq('<title inertia="title">Inertia Is Great</title>')
      end
    end
  end
end
