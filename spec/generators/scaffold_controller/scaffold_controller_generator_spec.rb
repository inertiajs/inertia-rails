# frozen_string_literal: true

require_relative '../../../lib/generators/inertia/scaffold_controller/scaffold_controller_generator'
require_relative '../../../lib/generators/inertia_templates/scaffold/scaffold_generator'
require 'generator_spec'

RSpec.describe Inertia::Generators::ScaffoldControllerGenerator, type: :generator do
  destination File.expand_path('../../../tmp/scaffold_controller_generator', __dir__)

  before { prepare_destination }

  describe 'strong parameters' do
    it 'uses flat params.permit with no model envelope' do
      run_generator %w[Ticket name:string --orm=active_record --frontend-framework=react]

      content = File.read(File.join(destination_root, 'app/controllers/tickets_controller.rb'))
      expect(content).to include('params.permit(:name)')
      expect(content).not_to include('params.expect')
      expect(content).not_to include('params.require')
    end

    it 'does not add wrap_parameters for namespaced controllers' do
      run_generator %w[Admin::Ticket name:string --orm=active_record --frontend-framework=react]

      content = File.read(File.join(destination_root, 'app/controllers/admin/tickets_controller.rb'))
      expect(content).not_to include('wrap_parameters')
    end
  end
end
