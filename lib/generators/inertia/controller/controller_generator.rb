# frozen_string_literal: true

require 'rails/generators/rails/controller/controller_generator'
require 'inertia_rails/generators/helper'

module Inertia
  module Generators
    class ControllerGenerator < Rails::Generators::ControllerGenerator
      include InertiaRails::Generators::Helper

      source_root File.expand_path('./templates', __dir__)

      remove_hook_for :template_engine

      hook_for :inertia_templates, required: true, default: InertiaRails::Generators::Helper.guess_inertia_template
    end
  end
end
