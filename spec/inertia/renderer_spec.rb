# frozen_string_literal: true

RSpec.describe InertiaRails::Renderer do
  let(:deprecator) do
    double(warn: nil).tap do |deprecator|
      allow(InertiaRails).to receive(:deprecator).and_return(deprecator)
    end
  end

  %i[component configuration controller props view_data encrypt_history clear_history].each do |method_name|
    it "has a deprecated #{method_name} accessor" do
      configuration = double('configuration',
                             encrypt_history: true,
                             deep_merge_shared_data: false,
                             clear_history: false)

      controller = double('controller',
                          inertia_configuration: configuration,
                          inertia_view_assigns: {},
                          session: {},
                          inertia_shared_data: {})

      request = double('request', headers: {})
      response = double('response', headers: {}, set_header: nil)
      render_method = ->(args) {}

      renderer = InertiaRails::Renderer.new('MyComponent', controller, request, response, render_method)

      expect(deprecator).to receive(:warn)
        .with(
          "[DEPRECATION] Accessing `InertiaRails::Renderer##{method_name}` is deprecated and will be removed in v4.0"
        )

      renderer.send(method_name)
    end
  end
end
