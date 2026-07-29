# frozen_string_literal: true

module InertiaRails
  module Devtools
    module ComponentPathLocator
      DEFAULT_ROOTS = %w[
        app/frontend/pages
        app/frontend/Pages
        app/javascript/pages
        app/javascript/Pages
      ].freeze

      EXTENSIONS = %w[jsx tsx vue svelte js ts].freeze

      class << self
        def resolve(component)
          return if component.blank?

          # Keyed on the roots too: reconfiguring the search paths must not keep
          # serving a hit found under the old ones.
          search_roots = roots
          cache[[search_roots, component]] ||= find(search_roots, component)
        end

        private

        def cache
          @cache ||= {}
        end

        def find(search_roots, component)
          search_roots.each do |root|
            EXTENSIONS.each do |extension|
              path = File.join(root, "#{component}.#{extension}")
              return path if File.file?(path)
            end
          end

          nil
        end

        def roots
          configured = InertiaRails.configuration.devtools_component_paths
          paths = configured ? Array(configured) : DEFAULT_ROOTS
          paths.map { |path| File.expand_path(path.to_s, Rails.root.to_s) }
        end
      end
    end
  end
end
