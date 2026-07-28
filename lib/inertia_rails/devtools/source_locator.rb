# frozen_string_literal: true

module InertiaRails
  module Devtools
    # Resolves the `{file, line}` pairs the DevTools panel turns into editor links.
    module SourceLocator
      MAX_SCAN_LINES = 100
      LIB_ROOT = File.expand_path('../..', __dir__)
      CACHE_KEY = :inertia_rails_devtools_source_lines

      class << self
        # The frame that called into the gem — the user's `render inertia:` or
        # `inertia_share` line, not the adapter's own plumbing.
        def caller_source(locations = caller_locations(1, 30))
          location = Array(locations).find { |candidate| app_frame?(candidate.absolute_path) }
          location && { file: location.absolute_path, line: location.lineno }
        end

        def method_source(owner, method_name)
          file, line = owner.instance_method(method_name).source_location
          file && { file: file, line: line }
        rescue NameError
          nil
        end

        def block_source(block)
          file, line = block.source_location
          file && { file: file, line: line }
        rescue StandardError
          nil
        end

        # Narrows a call site to the line the individual prop key sits on, so a
        # multi-key `render inertia:` links each prop to its own line.
        def prop_key_line(file, start_line, key)
          lines = source_lines(file)
          return unless lines

          pattern = /(?:^|[^\w:])#{Regexp.escape(key.to_s)}:(?!:)|['"]#{Regexp.escape(key.to_s)}['"]\s*(?:=>|:)/
          last = [start_line + MAX_SCAN_LINES, lines.length].min

          (start_line..last).each do |number|
            return number if pattern.match?(lines[number - 1].to_s)
          end

          nil
        end

        def refine(source, key)
          return source unless source

          line = prop_key_line(source[:file], source[:line], key)
          line ? { file: source[:file], line: line } : source
        end

        def clear_cache!
          Thread.current[CACHE_KEY] = nil
        end

        private

        def app_frame?(path)
          return false if path.nil?
          return false if path.start_with?(LIB_ROOT)
          return false unless defined?(Rails) && Rails.respond_to?(:root) && Rails.root

          path.start_with?(Rails.root.to_s) && !path.include?('/vendor/bundle/')
        end

        # Per-request, so an edit mid-session is never read from a stale cache.
        def source_lines(file)
          cache = (Thread.current[CACHE_KEY] ||= {})
          return cache[file] if cache.key?(file)

          cache[file] = (File.readlines(file) if file && File.file?(file))
        rescue StandardError
          cache[file] = nil
        end
      end
    end
  end
end
