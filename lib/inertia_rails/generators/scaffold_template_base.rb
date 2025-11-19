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
          template "#{options.frontend_framework}/#{view}.#{template_extension}",
                   File.join(base_path, "#{view}.#{extension}")
        end

        template "#{options.frontend_framework}/#{partial_name}.#{template_extension}",
                 File.join(base_path, "#{singular_name}.#{extension}")

        template "#{options.frontend_framework}/types.ts", File.join(base_path, 'types.ts') if typescript?
      end

      private

      def template_extension
        return extension unless typescript?
        return 'tsx' if options.frontend_framework == 'react'

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
