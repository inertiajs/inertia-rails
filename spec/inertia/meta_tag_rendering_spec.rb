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

    expect(response.parsed_body['props']['_inertia_meta']).to eq([
      {
        'tagName' => 'meta',
        'name' => 'description',
        'content' => 'Inertia rules',
        'headKey' => 'first_head_key',
      },
      {
        'tagName' => 'title',
        'innerContent' => 'The Inertia title',
        'headKey' => 'second_head_key',
      },
      {
        'tagName' => 'meta',
        'httpEquiv' => 'content-security-policy',
        'content' => "default-src 'self';",
        'headKey' => 'third_head_key',
      }
    ])
  end

  context 'with multiple title tags' do
    it 'only renders the last title tag' do
      get multiple_title_tags_meta_path, headers: headers

      expect(response.parsed_body['props']['_inertia_meta']).to eq([
        {
          'tagName' => 'title',
          'innerContent' => 'The second Inertia title',
          'headKey' => 'second_head_key',
        }
      ])
    end
  end

  context 'with a before filter setting meta tags' do
    it 'returns the meta tag set from the before filter' do
      get from_before_filter_meta_path, headers: headers

      expect(response.parsed_body['props']['_inertia_meta']).to eq([
        {
          'tagName' => 'meta',
          'name' => 'description',
          'content' => 'This is a description set from a before filter',
          'headKey' => 'before_filter_tag'
        }
      ])
    end
  end

  context 'with duplicate head keys' do
    it 'returns the last meta tag with the same head key' do
      get with_duplicate_head_keys_meta_path, headers: headers

      expect(response.parsed_body['props']['_inertia_meta']).to eq([
        {
          'tagName' => 'meta',
          'name' => 'description',
          'content' => 'This is another description',
          'headKey' => 'duplicate_key'
        }
      ])
    end
  end

  context 'with meta tags set from a module' do
    it 'overrides the meta tag set from the module' do
      get override_tags_from_module_meta_path, headers: headers

      expect(response.parsed_body['props']['_inertia_meta']).to eq([
        {
          'tagName' => 'meta',
          'name' => 'meta_tag_from_concern',
          'content' => 'This is overriden by the controller',
          'headKey' => 'meta_tag_from_concern'
        }
      ])
    end
  end
end
