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
        'head-key' => 'first_head_key',
      },
      {
        'tagName' => 'title',
        'content' => 'The Inertia title',
        'head-key' => 'second_head_key',
      },
      {
        'tagName' => 'meta',
        'http-equiv' => 'content-security-policy',
        'content' => "default-src 'self';",
        'head-key' => 'third_head_key',
      }
    ])
  end
end
