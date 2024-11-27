# frozen_string_literal: true

require 'inertia_rails/generators/controller_template_base'

module InertiaTwTemplates
  module Generators
    class ControllerGenerator < InertiaRails::Generators::ControllerTemplateBase
      hide!
      source_root File.expand_path('./templates', __dir__)
    end
  end
end
