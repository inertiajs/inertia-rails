# frozen_string_literal: true

module InertiaRails
  module Generators
    module Helper
      class << self
        def guess_the_default_framework(package_json_path = Rails.root.join('package.json'))
          package_json = JSON.parse(package_json_path.read)
          dependencies = package_json['dependencies'] || {}

          if dependencies['@inertiajs/react']
            'react'
          elsif dependencies['@inertiajs/svelte']
            version = dependencies['svelte'].gsub(/[\^~]/, '') # Remove ^ or ~ from version
            version.start_with?('5') ? 'svelte' : 'svelte4'
          elsif dependencies['@inertiajs/vue3']
            'vue'
          else
            Thor::Shell::Basic.new.say_error 'Could not determine the Inertia.js framework you are using.'
            exit 1
          end
        end

        def guess_typescript
          Rails.root.join('tsconfig.json').exist?
        end

        def guess_inertia_template
          if Rails.root.join('tailwind.config.js').exist? || Rails.root.join('tailwind.config.ts').exist?
            'inertia_tw_templates'
          else
            'inertia_templates'
          end
        end
      end

      def inertia_base_path
        (class_path + [file_name]).map(&:camelize).join('/')
      end

      def inertia_component_name
        singular_name.camelize
      end

      def inertia_model_type
        "#{inertia_component_name}Type"
      end

      def inertia_model_form_type
        "#{inertia_component_name}FormType"
      end

      def attributes_to_serialize
        [:id] + attributes.reject do |attribute|
          attribute.password_digest? ||
            attribute.attachment? ||
            attribute.attachments?
        end.map(&:column_name)
      end

      def custom_form_attributes
        attributes.select do |attribute|
          attribute.password_digest? ||
            attribute.attachment? ||
            attribute.attachments?
        end
      end

      def omit_input_attributes
        ['id'] + attributes.select { |attribute| attribute.attachment? || attribute.attachments? }.map(&:column_name)
      end

      def js_resource_path
        "#{route_url}/${#{singular_table_name}.id}"
      end

      def js_edit_resource_path
        "#{route_url}/${#{singular_table_name}.id}/edit"
      end

      def js_new_resource_path
        "#{route_url}/new"
      end

      def js_resources_path
        route_url
      end

      def inertia_js_version
        @inertia_js_version ||= Gem::Version.new(
          JSON.parse(`npm ls @inertiajs/core --json`).then do |json|
            json['dependencies'].values.first['version']
          end
        )
      end

      def ts_type(attribute)
        case attribute.type
        when :float, :decimal, :integer
          'number'
        when :boolean
          'boolean'
        when :attachment
          '{ filename: string; url: string }'
        when :attachments
          '{ filename: string; url: string }[]'
        else
          'string'
        end
      end

      def input_type(attribute)
        case attribute.type
        when :text, :rich_text
          'text_area'
        when :integer, :float, :decimal
          'number'
        when :datetime, :timestamp, :time
          'datetime-local'
        when :date
          'date'
        when :boolean
          'checkbox'
        when :attachments, :attachment
          'file'
        else
          'text'
        end
      end

      def default_value(attribute)
        case attribute.type
        when :boolean
          'false'
        else
          "''"
        end
      end
    end
  end
end
