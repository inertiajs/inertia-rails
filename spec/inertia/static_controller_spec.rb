# frozen_string_literal: true

RSpec.describe 'InertiaRails::StaticController' do
  def reload_static_controller!
    InertiaRails.send(:remove_const, :StaticController) if InertiaRails.const_defined?(:StaticController, false)
    load File.expand_path('../../app/controllers/inertia_rails/static_controller.rb', __dir__)
  end

  context 'when parent_controller does not inherit from ActionController::Base' do
    it 'loads the controller class but raises when the action runs' do
      original = InertiaRails.configuration.parent_controller
      stub_const('ApiParentController', Class.new(ActionController::API))
      InertiaRails.configure { |config| config.parent_controller = 'ApiParentController' }

      expect { reload_static_controller! }.not_to raise_error

      env = Rack::MockRequest.env_for('/about', params: { component: 'About' })
      expect do
        InertiaRails::StaticController.action(:static).call(env)
      end.to raise_error(ArgumentError, /must inherit from ActionController::Base/)
    ensure
      InertiaRails.configure { |config| config.parent_controller = original }
      reload_static_controller!
    end
  end
end
