# frozen_string_literal: true

require 'rails/generators/resource_helpers'
require 'inertia_rails/generators/helper'

module Inertia
  module Generators
    # This class is a modified copy of Rails::Generators::ScaffoldControllerGenerator.
    # We don't use inheritance because some gems (i.e. jsbuilder) monkey-patch it.
    class ScaffoldControllerGenerator < Rails::Generators::NamedBase
      include InertiaRails::Generators::Helper
      include Rails::Generators::ResourceHelpers

      source_root File.expand_path('./templates', __dir__)

      check_class_collision suffix: 'Controller'

      class_option :helper, type: :boolean
      class_option :orm, banner: 'NAME', type: :string, required: true,
                         desc: 'ORM to generate the controller for'

      class_option :skip_routes, type: :boolean, desc: "Don't add routes to config/routes.rb."

      argument :attributes, type: :array, default: [], banner: 'field:type field:type'

      def create_controller_files
        template 'controller.rb',
                 File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb")
      end

      hook_for :inertia_templates, as: :scaffold, required: true,
                                   default: InertiaRails::Generators::Helper.guess_inertia_template

      hook_for :resource_route, in: :rails, required: true do |route|
        invoke route unless options.skip_routes?
      end

      hook_for :test_framework, in: :rails, as: :scaffold

      # Invoke the helper using the controller name (pluralized)
      hook_for :helper, in: :rails, as: :scaffold do |invoked|
        invoke invoked, [controller_name]
      end

      private

      def permitted_params
        attachments, others = attributes_names.partition { |name| attachments?(name) }
        params = others.map { |name| ":#{name}" }
        params += attachments.map { |name| "#{name}: []" }
        params.join(', ')
      end

      def attachments?(name)
        attribute = attributes.find { |attr| attr.name == name }
        attribute&.attachments?
      end
    end
  end
end
