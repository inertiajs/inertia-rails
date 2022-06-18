require_relative '../../lib/inertia_rails/rspec'

RSpec.describe 'rendering when mimicking rails behavior', type: :request, inertia: true do

  context 'the props are provided by instance variables' do
    it 'has the props' do
      get instance_props_test_path

      expect_inertia.to include_props({'name' => 'Brandon', 'sport' => 'hockey'})
    end
  end

  context 'no component name is provided' do
    it 'has the correct derived component name' do
      get default_component_test_path

      expect_inertia.to render_component('inertia_rails_mimic/default_component_test')
    end

    it 'works with a neat shortcut' do
      get default_component_shortcut_test_path

      expect_inertia.to render_component('inertia_rails_mimic/default_component_shortcut_test')
    end
  end

  context 'no render is done at all and default_render is enabled' do
    it 'renders via inertia' do
      get default_render_test_path

      expect_inertia.to render_component('inertia_rails_mimic/default_render_test')
      expect_inertia.to include_props({'name' => 'Brian'})
    end
  end
end

