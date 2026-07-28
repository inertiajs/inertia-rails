# frozen_string_literal: true

module InertiaRails
  module Devtools
    # Best-effort mapping from a component name to the page file backing it, so
    # the panel can offer an editor link. A miss is not an error.
    module ComponentPathLocator
      DEFAULT_ROOTS = %w[
        app/frontend/pages
        app/frontend/Pages
        app/javascript/pages
        app/javascript/Pages
      ].freeze

      EXTENSIONS = %w[jsx tsx vue svelte js ts].freeze

      class << self
        # Only hits are cached: a page file added mid-session should resolve on
        # the next render rather than stay missing for the life of the process.
        def resolve(component)
          return if component.blank?

          cache[component] ||= find(component)
        end

        def clear_cache!
          @cache = nil
        end

        private

        def cache
          @cache ||= {}
        end

        def find(component)
          roots.each do |root|
            EXTENSIONS.each do |extension|
              path = File.join(root, "#{component}.#{extension}")
              return relative(path) if File.file?(path)
            end
          end

          nil
        end

        def roots
          configured = InertiaRails.configuration.devtools_component_paths
          paths = configured ? Array(configured) : DEFAULT_ROOTS

          paths.map { |path| File.expand_path(path.to_s, Rails.root.to_s) }
        end

        def relative(path)
          path.delete_prefix("#{Rails.root}/")
        end
      end
    end
  end
end
