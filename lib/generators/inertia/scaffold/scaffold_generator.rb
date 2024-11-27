# frozen_string_literal: true

require 'rails/generators/rails/resource/resource_generator'

module Inertia
  module Generators
    class ScaffoldGenerator < Rails::Generators::ResourceGenerator # :nodoc:
      remove_hook_for :resource_controller
      remove_class_option :actions

      class_option :resource_route, type: :boolean

      hook_for :scaffold_controller, required: true
    end
  end
end
