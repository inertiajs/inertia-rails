# Specs as documentation. Per-action shared data isn't explicity supported,
# but it can be done by referencing the action name in an inertia_share block.
RSpec.describe "conditionally shared data in a controller", type: :request do
  context "when there is data inside inertia_share only applicable to a single action" do
    it "does not leak the data between requests" do
      get conditional_share_show_path, headers: {'X-Inertia' => true}
      expect(JSON.parse(response.body)['props'].deep_symbolize_keys).to eq({
        normal_shared_prop: 1,
        show_only_prop: 1,
        conditionally_shared_show_prop: 1,
      })

      get conditional_share_index_path, headers: {'X-Inertia' => true}
      expect(JSON.parse(response.body)['props'].deep_symbolize_keys).not_to include({
        conditionally_shared_show_prop: 1,
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

  context "when there is conditional data shared via before_action" do
    it "raises an error because it is frozen" do
      # InertiaSharedData isn't frozen until after the first time it's accessed.
      InertiaConditionalSharingController.send(:_inertia_shared_data)

      expect {
        get conditional_share_show_with_a_problem_path, headers: {'X-Inertia' => true}
      }.to raise_error(FrozenError)
    end
  end
end
