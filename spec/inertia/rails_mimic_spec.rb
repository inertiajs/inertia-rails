# frozen_string_literal: true

require_relative '../../lib/inertia_rails/rspec'

RSpec.describe 'rendering when mimicking rails behavior', type: :request, inertia: true do
  context 'the props are provided by instance variables' do
    it 'has the props' do
      get instance_props_test_path

      expect_inertia.to have_exact_props({ name: 'Brandon', sport: 'hockey' })
    end
  end

  context 'props are explicitly provided' do
    it 'only includes the provided props' do
      get provided_props_test_path

      expect_inertia.to have_exact_props({ sport: 'basketball' })
    end
  end

  context 'no component name is provided' do
    it 'has the correct derived component name' do
      get default_component_test_path

      expect_inertia.to render_component('inertia_rails_mimic/default_component_test')
    end

    it 'has the correct derived component with props' do
      get default_component_with_props_test_path

      expect_inertia.to render_component('inertia_rails_mimic/default_component_with_props_test')
        .and have_exact_props({ my: 'props' })
    end

    it 'raises an error when props as properties are provided' do
      expect do
        get default_component_with_duplicated_props_test_path
      end.to raise_error(ArgumentError, 'Parameter `props` is not allowed when passing a Hash as the first argument')
    end
  end

  context 'no render is done at all and default_render is enabled' do
    it 'renders via inertia' do
      get default_render_test_path

      expect_inertia.to render_component('inertia_rails_mimic/default_render_test')
      expect_inertia.to include_props({ name: 'Brian' })
    end

    context 'a rendering transformation is provided' do
      it 'renders based on the transformation' do
        get transformed_default_render_test_path

        expect_inertia.to render_component('TransformedInertiaRailsMimic/RenderTest')
      end
    end
  end
end
