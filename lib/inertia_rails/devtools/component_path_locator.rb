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

          cache[component] ||= find(component)
        end

        private

        def cache
          @cache ||= {}
        end

        def find(component)
          roots.each do |root|
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
