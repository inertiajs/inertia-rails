# frozen_string_literal: true

require 'rails/generators/test_unit/scaffold/scaffold_generator'

module Inertia
  module TestUnit
    module Generators
      class ScaffoldGenerator < ::TestUnit::Generators::ScaffoldGenerator
        # Rails' find_by_namespace("test_unit", "inertia", "scaffold") builds lookups as
        # ["inertia:test_unit", "test_unit:scaffold"]. We need namespace "inertia:test_unit"
        # (not "inertia:test_unit:scaffold") so the hook picks us up before falling back to
        # the Rails default.
        namespace 'inertia:test_unit'

        # Search application overrides before the bundled scaffold templates.
        source_paths.concat(superclass.source_paths)
        source_paths << File.expand_path('./test_unit/templates', __dir__)
        source_root superclass.source_root

        private

        def flat_attributes_literal
          pairs = attributes_hash.map { |name, value| "#{name}: #{value}" }
          pairs.empty? ? '{}' : "{ #{pairs.join(', ')} }"
        end
      end
    end
  end
end
