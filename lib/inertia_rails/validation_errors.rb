# frozen_string_literal: true

module InertiaRails
  module ValidationErrors
    class << self
      # { user: { name: ["can't be blank"] } } #=> { "user.name" => ["can't be blank"] }
      # { "addresses[0].street": ["can't be blank"] } #=> { "addresses.0.street" => ["can't be blank"] }
      def flatten(errors)
        flatten_into(errors, nil, {})
      end

      private

      def flatten_into(errors, prefix, flat)
        errors.to_hash.each do |key, value|
          key = key.to_s.gsub(/\[(\d+)\]/, '.\1')
          key = "#{prefix}.#{key}" if prefix

          if value.respond_to?(:to_hash)
            flatten_into(value, key, flat)
          else
            flat[key] = value
          end
        end

        flat
      end
    end
  end
end
