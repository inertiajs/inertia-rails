RSpec.describe "conditionally shared data in a controller", type: :request do
  context "when there is conditional data inside inertia_share" do
    it "does not leak data between requests" do
      get conditional_share_index_path, headers: { 'X-Inertia' => true }
      expect(JSON.parse(response.body)['props'].deep_symbolize_keys).to eq({
                                                                             index_only_prop: 1,
                                                                             normal_shared_prop: 1,
                                                                           })

      get conditional_share_show_path, headers: { 'X-Inertia' => true }
      expect(JSON.parse(response.body)['props'].deep_symbolize_keys).to eq({
                                                                             normal_shared_prop: 1,
                                                                             show_only_prop: 1,
                                                                             conditionally_shared_show_prop: 1,
                                                                           })

      get conditional_share_index_path, headers: { 'X-Inertia' => true }
      expect(JSON.parse(response.body)['props'].deep_symbolize_keys).to eq({
                                                                             index_only_prop: 1,
                                                                             normal_shared_prop: 1,
                                                                           })
      get conditional_share_edit_path, headers: { 'X-Inertia' => true }
      expect(JSON.parse(response.body)['props'].deep_symbolize_keys).to eq({
                                                                             normal_shared_prop: 1,
                                                                             only_block_prop: 1,
                                                                             except_block_prop: 1,
                                                                             if_proc_prop: 1,
                                                                             unless_proc_prop: 1,
                                                                             only_prop: 1,
                                                                             if_prop: 1,
                                                                             unless_prop: 1,
                                                                             only_if_prop: 1,
                                                                             except_if_prop: 1,
                                                                             edit_only_prop: 1,
                                                                           })
    end
  end
end
