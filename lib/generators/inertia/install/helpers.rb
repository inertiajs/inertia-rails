# frozen_string_literal: true

module Inertia
  module Generators
    module Helpers
      ### FS Helpers
      def js_destination_path
        return ViteRuby.config.source_code_dir if defined?(ViteRuby)

        if file?('config/vite.json')
          source_code_dir = JSON.parse(File.read(file_path('config/vite.json'))).dig('all', 'sourceCodeDir')
          return source_code_dir if source_code_dir
        end

        'app/frontend'
      end

      def js_destination_root
        file_path(js_destination_path)
      end

      def js_file_path(*relative_path)
        File.join(js_destination_root, *relative_path)
      end

      def file?(*relative_path)
        File.file?(file_path(*relative_path))
      end

      def file_path(*relative_path)
        File.join(destination_root, *relative_path)
      end

      # Interactivity Helpers
      def ask(*)
        unless options[:interactive]
          say_error 'Specify all options when running the generator non-interactively.', :red
          exit(1)
        end

        super
      end

      def yes?(*)
        return false unless options[:interactive]

        super
      end
    end
  end
end
