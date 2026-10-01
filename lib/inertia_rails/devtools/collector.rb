# frozen_string_literal: true

module InertiaRails
  module Devtools
    class Collector
      PLAIN_ROW = { shared: false, inertiaType: nil }.freeze
      COMPONENT_EXTENSIONS = %w[jsx tsx vue svelte js ts].freeze
      MISSING = Object.new.freeze
      private_constant :MISSING

      attr_reader :component
      attr_accessor :page

      def initialize(component:, render_source:, share_sources:, shared_keys:)
        @component = component
        @render_source = render_source
        @share_sources = share_sources
        @shared_keys = shared_keys
        @rows = {}
        @page = nil
      end

      def add_prop(path, badges, reset: false)
        row = { shared: @shared_keys.include?(path), inertiaType: badges[:inertiaType] }
        row.merge!(badges.except(:inertiaType).select { |_, value| value })
        row[:reset] = true if reset

        @rows[path] = row
      end

      def build
        rows = @rows.filter_map do |path, row|
          if rescued?(path) then [path, row.merge(rescued: true)]
          elsif listed?(path, row) && found?(page_json['props'], path) then [path, row]
          end
        end.to_h
        link_sources(rows)
        # Keys the resolver never saw, such as `errors`, get a plain row with no link.
        page_json['props'].each_key { |key| rows[key] ||= PLAIN_ROW }

        {
          props: rows,
          propValues: values_at(stored_page['props'], rows.keys),
          renderSource: @render_source,
          componentPath: component_path,
        }
      end

      def stored_page
        @stored_page ||=
          Redaction.redact_exact_keys(page_json).merge('url' => Redaction.redact_url(page_json['url']))
      end

      private

      def page_json
        @page_json ||= @page.as_json
      end

      def component_path
        return if @component.blank?

        candidates = Array(Devtools.config.component_paths).product(COMPONENT_EXTENSIONS).map do |root, extension|
          File.expand_path("#{root}/#{@component}.#{extension}", Rails.root)
        end
        candidates.find { |path| File.file?(path) }
      end

      # Nested props get a row of their own only when they carry a badge.
      def listed?(path, row)
        !path.include?('.') || row != PLAIN_ROW
      end

      def rescued?(path)
        page_json.fetch('rescuedProps', []).include?(path)
      end

      def shared?(path)
        @shared_keys.include?(top_key(path))
      end

      def top_key(path)
        path.split('.', 2).first
      end

      # A prop under a shared key links to its share; any other prop to the render call.
      def link_sources(rows)
        shared, rendered = rows.keys.partition { |path| shared?(path) }
        shared.each do |path|
          source = @share_sources[top_key(path)]
          rows[path] = rows[path].merge(shareSource: source) if source
        end
        return unless @render_source

        SourceLocator.key_sources(@render_source, rendered).each do |path, source|
          rows[path] = rows[path].merge(renderSource: source)
        end
      end

      def found?(props, path)
        !dig(props, path).equal?(MISSING)
      end

      def values_at(props, paths)
        paths.each_with_object({}) do |path, values|
          value = dig(props, path)
          values[path] = value unless value.equal?(MISSING)
        end
      end

      def dig(props, path)
        path.split('.').reduce(props) do |current, segment|
          case current
          when Hash
            return MISSING unless current.key?(segment)

            current[segment]
          when Array
            index = Integer(segment, exception: false)
            return MISSING unless index && index < current.length

            current[index]
          else
            return MISSING
          end
        end
      end
    end
  end
end
