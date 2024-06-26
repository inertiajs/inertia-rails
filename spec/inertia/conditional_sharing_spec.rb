RSpec.describe "conditionally shared data in a controller", type: :request do
  context "when there is conditional data inside inertia_share" do
    it "does not leak data between requests" do
      get conditional_share_index_path, headers: {'X-Inertia' => true}
      expect(JSON.parse(response.body)['props'].deep_symbolize_keys).to eq({
                                                                             index_only_prop: 1,
                                                                             normal_shared_prop: 1,
                                                                           })

      # NOTE: we actually have to run the show action twice since the new implementation
      # sets up a before_action within a before_action to share the data.
      # In effect, that means that the shared data isn't rendered until the second time the action is run.
      get conditional_share_show_path, headers: {'X-Inertia' => true}
      get conditional_share_show_path, headers: {'X-Inertia' => true}
      expect(JSON.parse(response.body)['props'].deep_symbolize_keys).to eq({
                                                                             normal_shared_prop: 1,
                                                                             show_only_prop: 1,
                                                                             conditionally_shared_show_prop: 1,
                                                                           })

      get conditional_share_index_path, headers: {'X-Inertia' => true}
      expect(JSON.parse(response.body)['props'].deep_symbolize_keys).to eq({
                                                                             index_only_prop: 1,
                                                                             normal_shared_prop: 1,
                                                                           })
    end
  end
end
