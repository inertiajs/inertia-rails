# frozen_string_literal: true

module Inertia
  module Generators
    class JSPackageManager
      def self.package_managers
        %w[npm yarn bun pnpm]
      end

      def initialize(generator)
        @generator = generator
      end

      def present?
        name.present?
      end

      def add_dependencies(*dependencies)
        options = @generator.options[:verbose] ? '' : ' --silent'
        @generator.in_root do
          @generator.run "#{name} add #{dependencies.join(' ')}#{options}"
        end
      end

      def name
        @name ||= @generator.options[:package_manager] || detect_package_manager
      end

      private

      def detect_package_manager
        return nil unless file?('package.json')

        if file?('package-lock.json')
          'npm'
        elsif file?('bun.lockb')
          'bun'
        elsif file?('pnpm-lock.yaml')
          'pnpm'
        else
          'yarn'
        end
      end

      def file?(*relative_path)
        @generator.file?(*relative_path)
      end
    end
  end
end
