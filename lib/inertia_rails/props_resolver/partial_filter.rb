# frozen_string_literal: true

require 'set'

module InertiaRails
  class PropsResolver
    class PartialFilter
      def self.build(only, except)
        new(only, except) unless only.empty? && except.empty?
      end

      def initialize(only, except)
        @only = only.to_set
        @except = except.to_set
        @only_parents = parents_of(@only)
        @parents = @only_parents | parents_of(@except)
      end

      def selected?(path)
        return false if covers?(@except, path)

        @only.empty? || @only_parents.include?(path) || covers?(@only, path)
      end

      def names_children?(path)
        @parents.include?(path)
      end

      private

      def parents_of(paths)
        paths.each_with_object(Set.new) do |path, parents|
          each_parent(path) { |parent| parents << parent }
        end
      end

      def covers?(paths, path)
        return false if paths.empty?
        return true if paths.include?(path)

        each_parent(path) { |parent| return true if paths.include?(parent) }
        false
      end

      def each_parent(path)
        while (dot = path.rindex('.'))
          path = path[0, dot]
          yield path
        end
      end
    end
    private_constant :PartialFilter
  end
end
