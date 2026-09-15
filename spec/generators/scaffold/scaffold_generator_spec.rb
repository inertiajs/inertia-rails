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

  describe 'form template' do
    it 'does not use transform in react (jsx)' do
      run_generator %w[Ticket name:string --frontend-framework=react]
      content = File.read(File.join(destination_root, 'app/frontend/pages/tickets/form.jsx'))
      expect(content).not_to include('transform')
    end

    it 'does not use transform in react (tsx)' do
      run_generator %w[Ticket name:string --frontend-framework=react --typescript]
      content = File.read(File.join(destination_root, 'app/frontend/pages/tickets/form.tsx'))
      expect(content).not_to include('transform')
    end

    it 'does not use transform in vue' do
      run_generator %w[Ticket name:string --frontend-framework=vue]
      content = File.read(File.join(destination_root, 'app/frontend/pages/tickets/form.vue'))
      expect(content).not_to include('transform')
    end

    it 'does not use transform in vue (typescript)' do
      run_generator %w[Ticket name:string --frontend-framework=vue --typescript]
      content = File.read(File.join(destination_root, 'app/frontend/pages/tickets/form.vue'))
      expect(content).not_to include('transform')
    end

    it 'does not use transform in svelte' do
      run_generator %w[Ticket name:string --frontend-framework=svelte]
      content = File.read(File.join(destination_root, 'app/frontend/pages/tickets/form.svelte'))
      expect(content).not_to include('transform')
    end

    it 'does not use transform in svelte (typescript)' do
      run_generator %w[Ticket name:string --frontend-framework=svelte --typescript]
      content = File.read(File.join(destination_root, 'app/frontend/pages/tickets/form.svelte'))
      expect(content).not_to include('transform')
    end
  end
end
