# frozen_string_literal: true

require_relative '../../../lib/generators/inertia_templates/controller/controller_generator'
require 'generator_spec'

RSpec.describe InertiaTemplates::Generators::ControllerGenerator, type: :generator do
  destination File.expand_path('../../../tmp/controller_generator', __dir__)

  before { prepare_destination }

  it 'generates view filenames that match action names for nested controllers' do
    run_generator %w[Admin::Tickets index show_details --frontend-framework=react --typescript]

    views_path = File.join(destination_root, 'app/frontend/pages/admin/tickets')
    expect(Dir.children(views_path)).to contain_exactly('index.tsx', 'show_details.tsx')
  end
end
