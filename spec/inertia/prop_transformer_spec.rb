# frozen_string_literal: true

require_relative '../../lib/inertia_rails/rspec'
RSpec.describe 'props can be transformed', type: :request, inertia: true do
  let(:headers) do
    {
      'X-Inertia' => true,
      'X-Inertia-Partial-Component' => 'TestComponent',
    }
  end

  context 'props are provided' do
    it 'transforms the props' do
      get prop_transformer_test_path, headers: headers

      expect_inertia.to render_component('TestComponent')
        .and have_exact_props({
                                'LOWER_PROP' => 'lower_value',
                                'PARENT_HASH' => {
                                  'LOWER_CHILD_PROP' => 'lower_child_value',
                                },
                              })
    end
  end

  context 'props and meta are provided' do
    it 'transforms the props' do
      get prop_transformer_with_meta_test_path, headers: headers

      expect_inertia.to render_component('TestComponent')
        .and include_props({
                             'LOWER_PROP' => 'lower_value',
                           })
    end

    it 'does not transform the meta' do
      get prop_transformer_with_meta_test_path, headers: headers

      expect(response.parsed_body['props']['_inertia_meta']).to eq(
        [
          {
            'tagName' => 'meta',
            'name' => 'description',
            'content' => "Don't transform me!",
            'headKey' => 'meta-name-description',
          }
        ]
      )
    end
  end

  context 'no props are provided' do
    it 'does not error' do
      get prop_transformer_no_props_test_path, headers: headers

      expect_inertia.to render_component('TestComponent')
        .and have_exact_props({})
    end
  end
end
