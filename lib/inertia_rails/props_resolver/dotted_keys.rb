# frozen_string_literal: true

module InertiaRails
  class PropsResolver
    # Expands dot-notation keys: 'auth.user.name' => 'J' sets `name` in the hash at `auth.user`.
    class DottedKeys
      def initialize(props)
        @props = props
      end

      def expand
        dotted, plain = @props.partition { |key, _| key.to_s.include?('.') }
        result = plain.to_h { |key, value| [key.to_sym, value] }
        dotted.each do |key, value|
          path = key.to_s.split('.').map(&:to_sym)
          Key.new(path, value, overwrite: given_after?(key, path.first)).write_to(result)
        end
        result
      end

      private

      # Of 'auth.name' and `auth`, the one given last wins.
      def given_after?(key, other_key)
        positions[key.to_s] > positions.fetch(other_key.to_s, -1)
      end

      def positions
        @positions ||= @props.each_key.with_index.to_h { |key, index| [key.to_s, index] }
      end

      class Key
        def initialize(path, value, overwrite:)
          @key, *@nested_path = path
          @value = value
          @overwrite = overwrite
        end

        def write_to(hash)
          key = key_in(hash)
          if @nested_path.any?
            hash[key] = written_into(hash.fetch(key) { {} })
          elsif @overwrite || !hash.key?(key)
            hash[key] = @value
          end
          hash
        end

        def written_into(current)
          return current.add(self) if current.is_a?(Wrapper)
          return Wrapper.new(current).add(self) if current.is_a?(Proc) || PropsResolver.serializer?(current)

          if current.is_a?(Hash)
            nested_key.write_to(current.dup)
          elsif @overwrite
            nested_key.write_to({})
          else
            current
          end
        end

        private

        def key_in(hash)
          hash.key?(@key.to_s) ? @key.to_s : @key
        end

        def nested_key
          Key.new(@nested_path, @value, overwrite: @overwrite)
        end
      end

      # A closure or serializer, with the dotted keys to write into what it returns.
      # A prop type, so the walk calls it as the controller, and a partial reload can skip it.
      class Wrapper < BaseProp
        def initialize(value)
          super(&(value.is_a?(Proc) ? value : -> { value.to_inertia }))
          @keys = []
        end

        def add(key)
          @keys << key
          self
        end

        def call(controller, **)
          returned = super
          @keys.reduce(returned) { |props, key| key.written_into(props) }
        end
      end
      private_constant :Key, :Wrapper
    end
  end
end
