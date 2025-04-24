RSpec.describe InertiaRails::MetaTag do
  let(:meta_tag) { described_class.new(head_key: dummy_head_key, name: 'description', content: 'Inertia rules') }
  let(:dummy_head_key) { 'meta-12345678' }

  describe '#to_json' do
    it 'returns the meta tag as JSON' do
      expected_json = {
        tagName: :meta,
        'head-key' => dummy_head_key,
        name: 'description',
        content: 'Inertia rules'
      }.to_json

      expect(meta_tag.to_json).to eq(expected_json)
    end

    it 'transforms snake_case keys to kebab-case' do
      meta_tag = described_class.new(head_key: dummy_head_key, http_equiv: 'content-security-policy', content: "default-src 'self'")

      expected_json = {
        tagName: :meta,
        'head-key' => dummy_head_key,
        'http-equiv' => 'content-security-policy',
        content: "default-src 'self'"
      }.to_json

      expect(meta_tag.to_json).to eq(expected_json)
    end

    it 'handles JSON LD content' do
      meta_tag = described_class.new(tag_name: 'script', head_key: dummy_head_key, type: 'application/ld+json', content: { '@context': 'https://schema.org' })

      expected_json = {
        tagName: :script,
        'head-key' => dummy_head_key,
        type: 'application/ld+json',
        content: { '@context': 'https://schema.org' }
      }.to_json

      expect(meta_tag.to_json).to eq(expected_json)
    end

    it 'does not escape script tag content because Inertia.js adapters use innerHtml under the hood and browsers do not execute scripts added this way' do
      meta_tag = described_class.new(tag_name: 'script', head_key: dummy_head_key, content: '<script>alert("XSS")</script>')

      expected_json = {
        tagName: :script,
        'head-key' => dummy_head_key,
        content: '<script>alert("XSS")</script>'
      }.to_json

      expect(meta_tag.to_json).to eq(expected_json)
    end
  end

  describe "generated head keys" do
    it "generates a head-key of the format {tag name}-{hexdigest of tag content}" do
      meta_tag = described_class.new(name: 'description', content: 'Inertia rules')
      expected_head_key = "meta-#{Digest::MD5.hexdigest('content=Inertia rules&name=description')[0, 8]}"

      expect(meta_tag.as_json[:'head-key']).to eq(expected_head_key)
    end

    it "generates the same head-key regardless of hash data order" do
      first_tags = described_class.new(name: 'description', content: 'Inertia rules').as_json
      first_head_key = first_tags[:'head-key']

      second_tags = described_class.new(content: 'Inertia rules', name: 'description').as_json
      second_head_key = second_tags[:'head-key']

      expect(first_head_key).to eq(second_head_key)
    end

    it "generates a different head-key for different content" do
      first_tags = described_class.new(name: 'description', content: 'Inertia rules').as_json
      first_head_key = first_tags[:'head-key']

      second_tags = described_class.new(name: 'description', content: 'Inertia rocks').as_json
      second_head_key = second_tags[:'head-key']

      expect(first_head_key).not_to eq(second_head_key)
    end

    it "respects a user specified head_key" do
      custom_head_key = "blah"
      meta_tag = described_class.new(head_key: custom_head_key, name: 'description', content: 'Inertia rules')

      expect(meta_tag.as_json[:'head-key']).to eq(custom_head_key)
    end
  end

  describe "#to_tag" do
    let(:tag_helper) { ActionController::Base.helpers.tag }

    it "returns a string meta tag" do
      tag = meta_tag.to_tag(tag_helper)
      expect(tag).to be_a(String)
      expect(tag).to eq('<meta name="description" content="Inertia rules" inertia="meta-12345678">')
    end

    it "renders kebab case" do
      meta_tag = described_class.new(tag_name: :meta, head_key: dummy_head_key, 'http-equiv' => 'X-UA-Compatible', content: 'IE=edge')

      tag = meta_tag.to_tag(tag_helper)

      expect(tag).to eq('<meta http-equiv="X-UA-Compatible" content="IE=edge" inertia="meta-12345678">')
    end

    describe "script tag rendering" do
      it "renders JSON LD content correctly" do
        meta_tag = described_class.new(tag_name: :script, head_key: dummy_head_key, type: 'application/ld+json', content: { '@context': 'https://schema.org' })

        tag = meta_tag.to_tag(tag_helper)

        expect(tag).to eq('<script type="application/ld+json" inertia="meta-12345678">{"@context":"https://schema.org"}</script>')
      end

      it "escapes content by default" do
        meta_tag = described_class.new(tag_name: :meta, head_key: dummy_head_key, name: 'description', content: '<script>alert("XSS")</script>')

        tag = meta_tag.to_tag(tag_helper)

        expect(tag).to eq('<meta name="description" content="&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;" inertia="meta-12345678">')
      end

      context "when the tag is marked as raw" do
        it "does not escape script tag content" do
          meta_tag = described_class.new(tag_name: :script, head_key: dummy_head_key, content: '<script>alert("XSS")</script>', raw: true)

          tag = meta_tag.to_tag(tag_helper)

          expect(tag).to eq('<script inertia="meta-12345678"><script>alert("XSS")</script></script>')
        end
      end

      describe "rendering unary tags" do
        described_class::UNARY_TAGS.each do |tag_name|
          it "renders a content attribute for a #{tag_name} tag" do
            meta_tag = described_class.new(tag_name: tag_name, head_key: dummy_head_key, content: 'Inertia rules')

            tag = meta_tag.to_tag(tag_helper)

            expect(tag).to include("<#{tag_name} content=\"Inertia rules\" inertia=\"meta-12345678\">")
          end
        end
      end
    end
  end
end
