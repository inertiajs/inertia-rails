# frozen_string_literal: true

module InertiaRails
  module Devtools
    module SourceLocator
      DISPATCH_METHODS = %w[send_action process_action].freeze

      class << self
        def caller_source(locations = caller_locations(1, 30))
          location = locations.find { |candidate| app_frame?(candidate) }
          location && { file: location.absolute_path, line: location.lineno }
        end

        # The app line that called `render`, or the action itself when Rails rendered implicitly.
        def render_source(locations, controller)
          before_dispatch = locations.take_while { |location| !DISPATCH_METHODS.include?(location.base_label) }
          caller_source(before_dispatch) || RouteLocator.action_source(controller.request, controller)
        end

        def method_source(owner, method_name)
          return unless owner.public_method_defined?(method_name)

          file, line = owner.instance_method(method_name).source_location
          file && { file: file, line: line }
        end

        def block_source(block)
          file, line = block.source_location
          file && { file: file, line: line }
        end

        # Where each key is written inside the call at `source`, or the call's own line.
        def key_sources(source, keys)
          lines = key_lines(source)
          keys.index_with { |key| { file: source[:file], line: lines[key] || source[:line] } }
        end

        # Loaded on first use, so apps that never record don't pay for it at boot.
        def prism?
          return @prism if defined?(@prism)

          @prism = begin
            require 'prism'
            true
          rescue LoadError
            false
          end
        end

        private

        def app_frame?(location)
          path = location.absolute_path
          path&.start_with?("#{Rails.root}/") && !path.start_with?(Bundler.bundle_path.to_s)
        end

        # Line of each hash key in the call at `source`. Keys are also listed without their outer
        # keys, so `name` is found inside `props: { name: ... }`; outer keys win over inner ones.
        def key_lines(source)
          call = prism? && outermost_call(Prism.parse_file(source[:file]).value, source[:line])
          call ? collect_key_lines(call) : {}
        rescue SystemCallError
          {}
        end

        def outermost_call(root, line)
          queue = [root]
          while (node = queue.shift)
            return node if node.is_a?(Prism::CallNode) && node.location.start_line == line

            queue.concat(node.compact_child_nodes)
          end
        end

        def collect_key_lines(call)
          lines = {}
          queue = call.compact_child_nodes.map { |node| [node, []] }
          while (entry = queue.shift)
            node, path = entry
            key = node.is_a?(Prism::AssocNode) && node.key.respond_to?(:unescaped) && node.key.unescaped
            if key
              path += [key]
              path.each_index { |start| lines[path[start..].join('.')] ||= node.location.start_line }
              queue << [node.value, path]
            else
              queue.concat(node.compact_child_nodes.map { |child| [child, path] })
            end
          end
          lines
        end
      end
    end
  end
end
