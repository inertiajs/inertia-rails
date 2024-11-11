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
          filename = "#{view}.#{template_extension}"
          template "#{options.frontend_framework}/#{filename}", File.join(base_path, filename)
        end

        template "#{options.frontend_framework}/#{partial_name}.#{template_extension}",
                 File.join(base_path, "#{inertia_component_name}.#{extension}")
      end

      private

      def template_extension
        return extension unless typescript?
        return 'tsx' if options.frontend_framework == 'react'

        "ts.#{extension}"
      end

      def available_views
        %w[Index Edit Show New Form]
      end

      def partial_name
        'One'
      end
    end
  end
end
