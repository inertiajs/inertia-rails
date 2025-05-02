# frozen_string_literal: true

RSpec.describe 'rendering inertia meta tags', type: :request do
  let(:headers) do
    {
      'X-Inertia' => true,
      'X-Inertia-Partial-Component' => 'TestComponent',
    }
  end

  before { get basic_meta_path, headers: headers }

  it 'returns meta tag data' do
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
end
