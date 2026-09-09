# frozen_string_literal: true

module InertiaRails
  module Devtools
    module SourceLocator
      MAX_SCAN_LINES = 100
      LIB_ROOT = File.expand_path('../..', __dir__)
      CACHE_KEY = :inertia_rails_devtools_source_lines

      class << self
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

        private

        def app_frame?(path)
          return false if path.nil?
          return false if path.start_with?(LIB_ROOT)
          return false unless defined?(Rails) && Rails.respond_to?(:root) && Rails.root

          path.start_with?(Rails.root.to_s) && !path.include?('/vendor/bundle/')
        end

        def source_lines(file)
          return nil unless file

          cache = (Thread.current[CACHE_KEY] ||= {})
          mtime = File.mtime(file)
          cached_mtime, cached_lines = cache[file]
          return cached_lines if cached_mtime == mtime

          lines = File.readlines(file)
          cache[file] = [mtime, lines]
          lines
        rescue StandardError
          cache&.delete(file)
          nil
        end
      end
    end
  end
end
