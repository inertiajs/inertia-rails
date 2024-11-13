# frozen_string_literal: true

require 'rails/generators/named_base'
require 'inertia_rails/generators/helper'

module InertiaRails
  module Generators
    class ControllerTemplateBase < Rails::Generators::NamedBase
      include Helper
      class_option :frontend_framework, required: true, desc: 'Frontend framework to generate the views for.',
                                        default: Helper.guess_the_default_framework

      class_option :typescript, type: :boolean, desc: 'Whether to use TypeScript',
                                default: Helper.guess_typescript

      argument :actions, type: :array, default: [], banner: 'action action'

      def empty_views_dir
        empty_directory base_path
      end

      def copy_view_files
        actions.each do |action|
          @action = action
          @path = File.join(base_path, "#{action.camelize}.#{extension}")
          template "#{options.frontend_framework}/#{template_filename}.#{extension}", @path
        end
      end

      private

      def base_path
        File.join(pages_path, inertia_base_path)
      end

      def template_filename
        'view'
      end

      def pages_path
        "#{root_path}/pages"
      end

      def root_path
        (defined?(ViteRuby) ? ViteRuby.config.source_code_dir : 'app/frontend')
      end

      def extension
        case options.frontend_framework
        when 'react' then typescript? ? 'tsx' : 'jsx'
        when 'vue' then 'vue'
        when 'svelte', 'svelte4' then 'svelte'
        else
          raise ArgumentError, "Unknown frontend framework: #{options.frontend_framework}"
        end
      end

      def typescript?
        options.typescript
      end
    end
  end
end
