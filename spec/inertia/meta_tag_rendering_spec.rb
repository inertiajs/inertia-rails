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

    expect(response.parsed_body['meta']).to eq([
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

      expect(response.parsed_body['meta']).to eq([
        {
          'tagName' => 'title',
          'innerContent' => 'The second Inertia title',
          'headKey' => 'second_head_key',
        }
      ])
    end
  end
end
