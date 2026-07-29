# frozen_string_literal: true

module InertiaRails
  module Devtools
    class Collector
      attr_reader :component
      attr_accessor :page

      def initialize(component:, render_source: nil, share_sources: {}, shared_keys: [])
        @component = component
        @render_source = render_source
        @share_sources = share_sources
        @shared_keys = shared_keys
        @props = {}
        @page = nil
      end

      def add_prop(path, metadata, rescued: false)
        info = {
          shared: shared?(path),
          inertiaType: metadata[:inertiaType],
        }

        share_source = @share_sources[path]
        info[:deferGroup] = metadata[:deferGroup] if metadata[:deferGroup]
        info[:shareSource] = share_source if share_source
        info[:reset] = true if metadata[:reset]
        info[:once] = true if metadata[:once]
        info[:mergeDirection] = metadata[:mergeDirection] if metadata[:mergeDirection]
        info[:deepMerge] = true if metadata[:deepMerge]
        info[:rescued] = true if rescued

        @props[path] = info
      end

      def build
        @build ||= begin
          synchronize_props
          resolve_render_prop_lines
          props = prune_props

          {
            component: @component,
            props: props,
            propValues: prop_values(props.keys),
            renderSource: @render_source,
            componentPath: ComponentPathLocator.resolve(@component),
            responseBody: normalized_page,
          }
        end
      end

      private

      def synchronize_props
        props = normalized_page&.fetch('props', nil)
        return unless props.is_a?(Hash)

        @props.reject! { |path| dig_path(props, path) == :__missing__ }
        props.each_key do |key|
          @props[key.to_s] ||= { shared: false, inertiaType: nil }
        end
      end

      def shared?(path)
        @shared_keys.include?(path)
      end

      def resolve_render_prop_lines
        return unless @render_source

        @props.each do |path, info|
          next if info[:shared] || info[:shareSource]

          line = SourceLocator.prop_key_line(@render_source[:file], @render_source[:line], path)
          info[:renderSource] = { file: @render_source[:file], line: line } if line
        end
      end

      def prune_props
        @props.select { |path, info| !path.include?('.') || metadata?(info) }
      end

      def metadata?(info)
        info[:shared] || !info[:inertiaType].nil? || info.keys.length > 2
      end

      def normalized_page
        return @normalized_page if defined?(@normalized_page)

        @normalized_page = @page && JSON.parse(JSON.generate(@page.as_json))
      rescue StandardError
        @normalized_page = nil
      end

      def prop_values(paths)
        props = normalized_page && normalized_page['props']
        return {} unless props.is_a?(Hash)

        props = Redaction.redact(props)

        paths.each_with_object({}) do |path, values|
          value = dig_path(props, path)
          values[path] = value unless value == :__missing__
        end
      end

      def dig_path(props, path)
        path.split('.').reduce(props) do |current, segment|
          case current
          when Hash
            return :__missing__ unless current.key?(segment)

            current[segment]
          when Array
            index = Integer(segment, exception: false)
            return :__missing__ unless index && index < current.length

            current[index]
          else
            return :__missing__
          end
        end
      end
    end
  end
end
