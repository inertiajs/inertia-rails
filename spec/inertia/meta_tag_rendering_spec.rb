# frozen_string_literal: true

RSpec.describe 'rendering inertia meta tags', type: :request do
  let(:headers) do
    {
      'X-Inertia' => true,
      'X-Inertia-Partial-Component' => 'TestComponent',
    }
  end

  it 'returns meta tag data' do
    get basic_meta_path, headers: headers

    expect(response.parsed_body['props']['_inertia_meta']).to match_array(
      [
        {
          'tagName' => 'meta',
          'name' => 'description',
          'content' => 'Inertia rules',
          'headKey' => 'first_head_key',
        },
        {
          'tagName' => 'title',
          'innerContent' => 'The Inertia title',
          'headKey' => 'title',
        },
        {
          'tagName' => 'meta',
          'httpEquiv' => 'content-security-policy',
          'content' => "default-src 'self';",
          'headKey' => 'third_head_key',
        }
      ]
    )
  end

  context 'with multiple title tags' do
    it 'only renders the last title tag' do
      get multiple_title_tags_meta_path, headers: headers

      expect(response.parsed_body['props']['_inertia_meta']).to eq(
        [
          {
            'tagName' => 'title',
            'innerContent' => 'The second Inertia title',
            'headKey' => 'title',
          }
        ]
      )
    end
  end

  context 'with a before filter setting meta tags' do
    it 'returns the meta tag set from the before filter' do
      get from_before_filter_meta_path, headers: headers

      expect(response.parsed_body['props']['_inertia_meta']).to eq(
        [
          {
            'tagName' => 'meta',
            'name' => 'description',
            'content' => 'This is a description set from a before filter',
            'headKey' => 'before_filter_tag',
          }
        ]
      )
    end
  end

  context 'with duplicate head keys' do
    it 'returns the last meta tag with the same head key' do
      get with_duplicate_head_keys_meta_path, headers: headers

      expect(response.parsed_body['props']['_inertia_meta']).to eq(
        [
          {
            'tagName' => 'meta',
            'name' => 'description2', # Contrived mismatch between meta tag names to ensure head_key deduplication works
            'content' => 'This is another description',
            'headKey' => 'duplicate_key',
          }
        ]
      )
    end
  end

  context 'with meta tags set from a module' do
    it 'overrides the meta tag set from the module' do
      get override_tags_from_module_meta_path, headers: headers

      expect(response.parsed_body['props']['_inertia_meta']).to eq(
        [
          {
            'tagName' => 'meta',
            'name' => 'meta_tag_from_concern',
            'content' => 'This is overriden by the controller',
            'headKey' => 'meta_tag_from_concern',
          }
        ]
      )
    end
  end

  describe 'automatic deduplication without head_keys' do
    # Don't care what the auto generated head keys are, just check the content
    let(:meta_without_head_keys) do
      response.parsed_body['props']['_inertia_meta'].map do |tag|
        tag.reject { |properties| properties['headKey'] }
      end
    end

    it 'dedups on :name, :property, :http_equiv, :charset, and :itemprop keys' do
      get auto_dedup_meta_path, headers: headers

      expect(meta_without_head_keys).to match_array([
                                                      {
                                                        'tagName' => 'meta',
                                                        'name' => 'description',
                                                        'content' => 'Overridden description',
                                                      },
                                                      {
                                                        'tagName' => 'meta',
                                                        'property' => 'og:description',
                                                        'content' => 'Overridden Open Graph description',
                                                      },
                                                      {
                                                        'tagName' => 'meta',
                                                        'httpEquiv' => 'content-security-policy',
                                                        'content' => 'Overridden CSP',
                                                      },
                                                      {
                                                        'tagName' => 'meta',
                                                        'charset' => 'Overridden charset',
                                                      }
                                                    ])
    end

    it 'allows duplicates for specified meta tags' do
      get allowed_duplicates_meta_path, headers: headers

      expect(meta_without_head_keys).to match_array([
                                                      {
                                                        'tagName' => 'meta',
                                                        'property' => 'article:author',
                                                        'content' => 'Cassian Andor',
                                                      },
                                                      {
                                                        'tagName' => 'meta',
                                                        'property' => 'article:author',
                                                        'content' => 'Tony Gilroy',
                                                      }
                                                    ])
    end
  end

  it 'can clear meta tags' do
    get cleared_meta_path, headers: headers
    expect(response.parsed_body['props']['_inertia_meta']).not_to be
  end

  context 'with server_head enabled via per-controller config' do
    it 'returns meta tags as ready-to-render HTML strings in the head prop' do
      get server_head_meta_path, headers: headers

      expect(response.parsed_body['props']).not_to have_key('_inertia_meta')
      expect(response.parsed_body['props']['head']).to eq(
        [
          '<meta name="description" content="Inertia rules" data-inertia="first_head_key">',
          '<title data-inertia="title">The Inertia title</title>',
          '<meta http-equiv="content-security-policy" content="default-src &#39;self&#39;;" ' \
          'data-inertia="csp_key">',
          '<script type="application/ld+json" data-inertia="ld_json">{"@context":"https://schema.org"}</script>'
        ]
      )
    end

    it 'omits the prop when there are no meta tags' do
      get server_head_empty_meta_path, headers: headers

      expect(response.parsed_body['props']).not_to have_key('head')
    end

    it 'raises when a prop with the same name already exists' do
      expect do
        get server_head_collision_meta_path, headers: headers
      end.to raise_error(InertiaRails::Error, /`head` prop is reserved/)
    end

    it 'raises on the conflicting prop even when the page has no meta tags' do
      expect do
        get server_head_collision_without_meta_path, headers: headers
      end.to raise_error(InertiaRails::Error, /`head` prop is reserved/)
    end

    it 'raises for a deferred prop with the same name on the initial load' do
      expect do
        get server_head_collision_deferred_meta_path, headers: { 'X-Inertia' => true }
      end.to raise_error(InertiaRails::Error, /`head` prop is reserved/)
    end

    it 'raises on partial reloads whose `only` filter excludes the conflicting prop' do
      expect do
        get server_head_collision_meta_path, headers: headers.merge('X-Inertia-Partial-Data' => 'unrelated')
      end.to raise_error(InertiaRails::Error, /`head` prop is reserved/)
    end

    it 'raises when prop_transformer re-keys props to strings' do
      expect do
        get server_head_transformed_collision_meta_path, headers: headers
      end.to raise_error(InertiaRails::Error, /`head` prop is reserved/)
    end

    context 'with a custom prop name' do
      it 'serializes meta tags into the configured prop, leaving head free' do
        get server_head_custom_meta_path, headers: headers

        expect(response.parsed_body['props']['head']).to eq('no conflict with a custom prop name')
        expect(response.parsed_body['props']['custom_meta']).to eq(
          ['<meta name="description" content="Inertia rules" data-inertia="first_head_key">']
        )
      end
    end

    context 'on the initial (non-Inertia) request' do
      before { get server_head_meta_path }

      it 'renders the same strings into the layout head via inertia_meta_tags' do
        expect(response.body).to include(
          "<meta name=\"description\" content=\"Inertia rules\" data-inertia=\"first_head_key\">\n" \
          "<title data-inertia=\"title\">The Inertia title</title>\n" \
          '<meta http-equiv="content-security-policy" content="default-src &#39;self&#39;;" ' \
          "data-inertia=\"csp_key\">\n" \
          '<script type="application/ld+json" data-inertia="ld_json">{"@context":"https://schema.org"}</script>'
        )
      end

      it 'escapes the copy inside the initial page payload so it cannot break out' do
        expect(response.body.scan('<script type="application/ld+json"').count).to eq(1)
      end
    end

    context 'with SSR enabled' do
      def stub_ssr_success(body)
        http_response = instance_double(Net::HTTPOK, body: body.to_json, code: '200')
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        http_double = instance_double(Net::HTTP)
        allow(http_double).to receive(:post).and_return(http_response)
        allow(Net::HTTP).to receive(:start).and_yield(http_double)
      end

      it 'renders only the SSR-provided head, with nothing from inertia_meta_tags' do
        stub_ssr_success(
          body: '<div>SSR body</div>',
          head: ['<title data-inertia="title">SSR title</title>']
        )

        get server_head_ssr_meta_path

        expect(response.body.scan('<title data-inertia="title">').count).to eq(1)
        expect(response.body).to include('SSR title')
        expect(response.body).not_to include('The Inertia title')
      end

      it 'renders only inertia_meta_tags when SSR falls back' do
        allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED)

        get server_head_ssr_meta_path

        expect(response.body.scan('<title data-inertia="title">The Inertia title</title>').count).to eq(1)
      end
    end
  end

  context 'with default rendering' do
    it 'returns meta tags with default rendering' do
      get meta_with_default_render_path, headers: headers

      expect(response.parsed_body['props']['some']).to eq('prop')
      expect(response.parsed_body['props']['_inertia_meta']).to eq(
        [
          {
            'tagName' => 'meta',
            'name' => 'description',
            'content' => 'default rendering still works',
            'headKey' => 'meta-name-description',
          }
        ]
      )
    end
  end

  describe 'with a title template' do
    it 'runs in controller context with the current title' do
      get title_template_meta_path, headers: headers

      expect(response.parsed_body['props']['_inertia_meta']).to eq(
        [
          {
            'tagName' => 'title',
            'innerContent' => 'The Page - Inertia App',
            'headKey' => 'title',
          }
        ]
      )
    end

    it 'synthesizes a default title when the page defines none' do
      get title_template_default_meta_path, headers: headers

      expect(response.parsed_body['props']['_inertia_meta']).to eq(
        [
          {
            'tagName' => 'title',
            'innerContent' => 'Inertia App',
            'headKey' => 'title',
          }
        ]
      )
    end

    it 'raises when the template is not callable' do
      expect do
        get title_template_invalid_meta_path, headers: headers
      end.to raise_error(ArgumentError, /meta_title_template must be callable/)
    end

    context 'with server_head enabled' do
      it 'applies the template before serializing to HTML strings' do
        get server_head_title_template_meta_path, headers: headers

        expect(response.parsed_body['props']['head']).to eq(
          [
            '<title data-inertia="title">The Page - Inertia App</title>',
            '<meta name="description" content="Inertia rules" data-inertia="desc_key">'
          ]
        )
      end

      it 'renders the default title into the layout on the initial load' do
        get server_head_title_template_default_meta_path

        expect(response.body).to include('<title data-inertia="title">Inertia App</title>')
      end
    end
  end
end
