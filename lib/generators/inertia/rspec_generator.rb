# frozen_string_literal: true

begin
  require 'generators/rspec/scaffold/scaffold_generator'

  module Inertia
    module Rspec
      module Generators
        class ScaffoldGenerator < ::Rspec::Generators::ScaffoldGenerator
          # Rails' find_by_namespace("rspec", "inertia", "scaffold") builds lookups as
          # ["inertia:rspec", "rspec:scaffold"]. We need namespace "inertia:rspec" so the
          # hook picks us up before falling back to the rspec-rails default.
          namespace 'inertia:rspec'

          # Inertia apps have no ERB views, so view specs always fail with MissingTemplate.
          class_option :view_specs, type: :boolean, default: false

          # Our templates override the default ones (e.g. flat params instead of enveloped,
          # redirect assertions instead of 422 for invalid params).
          # The parent's source_root is appended so un-overridden templates fall through.
          source_paths.unshift(File.expand_path('./rspec/templates', __dir__))
          source_paths << ::Rspec::Generators::ScaffoldGenerator.source_root
        end
      end
    end
  end
rescue LoadError
  # rspec-rails not available
end
