# frozen_string_literal: true

require_relative '../../lib/inertia_rails/rspec'
RSpec.describe 'merge props can be transformed', type: :request, inertia: true do
  let(:headers) do
    {
      'X-Inertia' => true,
      'X-Inertia-Partial-Component' => 'TestComponent',
    }
  end

  context 'merge props are provided' do
    it 'transforms the merge props from snake_case to camelCase' do
      get merge_prop_transformer_test_path, headers: headers

      expect_inertia.to render_component('TestComponent')
        .and have_exact_props({
          'snake_case_merge' => 'merge prop',
          'another_snake_merge' => [{ 'id' => 1 }],
          'regular_prop' => 'regular prop',
        })

      # Check that mergeProps array contains transformed keys
      expect(response.parsed_body['mergeProps']).to eq(['snakeCaseMerge', 'anotherSnakeMerge'])
    end
  end

  context 'deep merge props are provided' do
    it 'transforms the deep merge props from snake_case to camelCase' do
      get merge_prop_transformer_deep_test_path, headers: headers

      expect_inertia.to render_component('TestComponent')
        .and have_exact_props({
          'snake_case_deep_merge' => { 'deep' => 'merge prop' },
          'another_snake_deep_merge' => { 'deep' => [{ 'id' => 1 }] },
          'regular_prop' => 'regular prop',
        })

      # Check that deepMergeProps array contains transformed keys
      expect(response.parsed_body['deepMergeProps']).to eq(['snakeCaseDeepMerge', 'anotherSnakeDeepMerge'])
    end
  end

  context 'both merge and deep merge props are provided' do
    it 'transforms both types of merge props from snake_case to camelCase' do
      get merge_prop_transformer_both_test_path, headers: headers

      expect_inertia.to render_component('TestComponent')
        .and have_exact_props({
          'snake_case_merge' => 'merge prop',
          'snake_case_deep_merge' => { 'deep' => 'merge prop' },
          'regular_prop' => 'regular prop',
        })

      # Check that both mergeProps and deepMergeProps arrays contain transformed keys
      expect(response.parsed_body['mergeProps']).to eq(['snakeCaseMerge'])
      expect(response.parsed_body['deepMergeProps']).to eq(['snakeCaseDeepMerge'])
    end
  end

  context 'no merge props are provided' do
    it 'does not error and does not include mergeProps or deepMergeProps' do
      get merge_prop_transformer_no_merge_test_path, headers: headers

      expect_inertia.to render_component('TestComponent')
        .and have_exact_props({
          'regular_prop' => 'regular prop',
        })

      # Check that no merge props arrays are present
      expect(response.parsed_body).not_to have_key('mergeProps')
      expect(response.parsed_body).not_to have_key('deepMergeProps')
    end
  end
end
