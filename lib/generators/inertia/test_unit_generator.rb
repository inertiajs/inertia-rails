# frozen_string_literal: true

require "rails/generators/test_unit/scaffold/scaffold_generator"

module Inertia
  module TestUnit
    module Generators
      class ScaffoldGenerator < ::TestUnit::Generators::ScaffoldGenerator
        # Rails' find_by_namespace("test_unit", "inertia", "scaffold") builds lookups as
        # ["inertia:test_unit", "test_unit:scaffold"]. We need namespace "inertia:test_unit"
        # (not "inertia:test_unit:scaffold") so the hook picks us up before falling back to
        # the Rails default.
        namespace "inertia:test_unit"

        # Our templates override the default ones (e.g. flat params instead of enveloped).
        # The parent's source_root is appended so un-overridden templates (system_test.rb.tt etc.)
        # still fall through to the Rails defaults.
        source_paths.unshift(File.expand_path("./test_unit/templates", __dir__))
        source_paths << ::TestUnit::Generators::ScaffoldGenerator.source_root
      end
    end
  end
end
