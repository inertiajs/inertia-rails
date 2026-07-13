# frozen_string_literal: true

require_relative '../../../lib/generators/inertia_templates/scaffold/scaffold_generator'
require 'generator_spec'

RSpec.describe InertiaTemplates::Generators::ScaffoldGenerator, type: :generator do
  destination File.expand_path('../../../tmp/scaffold_generator', __dir__)

  before { prepare_destination }

  it 'generates views under the pluralized controller path' do
    run_generator %w[Ticket name:string --frontend-framework=react --typescript]

    views_path = File.join(destination_root, 'app/frontend/pages/tickets')
    expect(Dir.children(views_path)).to contain_exactly(
      'index.tsx', 'edit.tsx', 'show.tsx', 'new.tsx', 'form.tsx', 'ticket.tsx', 'types.ts'
    )
  end
end
