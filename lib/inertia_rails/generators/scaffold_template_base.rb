# frozen_string_literal: true

require 'rails/generators/resource_helpers'
require_relative 'controller_template_base'

module InertiaRails
  module Generators
    class ScaffoldTemplateBase < ControllerTemplateBase
      include Rails::Generators::ResourceHelpers

      remove_argument :actions

      argument :attributes, type: :array, default: [], banner: 'field:type field:type'

      def copy_view_files
        available_views.each do |view|
          template "#{frontend_framework}/#{view}.#{template_extension}",
                   File.join(base_path, "#{view}.#{extension}")
        end

        template "#{frontend_framework}/#{partial_name}.#{template_extension}",
                 File.join(base_path, "#{singular_name}.#{extension}")

        template "#{frontend_framework}/types.ts", File.join(base_path, 'types.ts') if typescript?
      end

      private

      # Scaffold controllers are pluralized, so the views live under the pluralized path.
      def inertia_base_path
        (controller_class_path + [controller_file_name]).join('/')
      end

      def template_extension
        return extension unless typescript?
        return 'tsx' if frontend_framework == 'react'

        "ts.#{extension}"
      end

      def available_views
        %w[index edit show new form]
      end

      def partial_name
        'one'
      end
    end
  end
end
