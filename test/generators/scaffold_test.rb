# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'rails/generators'
require 'generators/inertia/test_unit_generator'

class ScaffoldTest < ActiveSupport::TestCase
  test 'the generated controller test compiles with the installed Rails version' do
    Dir.mktmpdir do |dir|
      Inertia::TestUnit::Generators::ScaffoldGenerator.start(
        %w[Ticket name:string --quiet], destination_root: dir
      )

      path = File.join(dir, 'test/controllers/tickets_controller_test.rb')
      assert_includes File.read(path), 'post tickets_url, params: { name: @ticket.name }'
      assert system(RbConfig.ruby, '-c', path, out: File::NULL)
    end
  end
end
