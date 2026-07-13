# frozen_string_literal: true

RSpec.describe 'conditionally shared data in a controller', type: :request do
  context 'when there is data inside inertia_share only applicable to a single action' do
    let(:edit_only_props) do
      {
        edit_only_only_block_prop: 1,
        edit_only_except_block_prop: 1,
        edit_only_if_proc_prop: 1,
        edit_only_unless_proc_prop: 1,
        edit_only_only_prop: 1,
        edit_only_if_prop: 1,
        edit_only_unless_prop: 1,
        edit_only_only_if_prop: 1,
        edit_only_except_if_prop: 1,
        edit_only_prop: 1,
      }
    end

    let(:show_only_props) do
      {
        show_only_prop: 1,
        conditionally_shared_show_prop: 1,
      }
    end

    let(:index_only_props) do
      {
        index_only_prop: 1,
      }
    end

    it 'does not leak the data between requests' do
      get conditional_share_show_path, headers: { 'X-Inertia' => true }
      expect(JSON.parse(response.body)['props'].symbolize_keys).to eq(show_only_props.merge(normal_shared_prop: 1))

      get conditional_share_index_path, headers: { 'X-Inertia' => true }
      expect(JSON.parse(response.body)['props'].symbolize_keys).to eq(index_only_props.merge(normal_shared_prop: 1))

      get conditional_share_edit_path, headers: { 'X-Inertia' => true }
      expect(JSON.parse(response.body)['props'].symbolize_keys).to eq(edit_only_props.merge(normal_shared_prop: 1))
    end
  end

  context 'when there is conditional data shared via before_action' do
    it 'works without raising an error' do
      get conditional_share_show_with_a_problem_path, headers: { 'X-Inertia' => true }
      props = JSON.parse(response.body)['props'].symbolize_keys
      expect(props).to include(incorrectly_conditionally_shared_prop: 1)
    end
  end
end
