require "rspec/core"
require "rspec/matchers"

module InertiaRails
  module RSpec
    class InertiaRenderWrapper
      attr_reader :view_data, :props, :component
    
      def initialize
        @view_data = nil
        @props = nil
        @component = nil
      end
    
      def call(params)
        set_values(params)
        @render_method&.call(params)
      end
    
      def wrap_render(render_method)
        @render_method = render_method
        self
      end
    
      protected
    
      def set_values(params)
        @view_data = params[:locals].except(:page)
        @props = params[:locals][:page][:props]
        @component = params[:locals][:page][:component]
      end
    end

    module Helpers
      def inertia
        raise 'Inertia test helpers aren\'t set up! Make sure you add inertia: true to describe blocks using inertia tests.' unless inertia_tests_setup?

        if @_inertia_render_wrapper.nil? && !::RSpec.configuration.inertia[:skip_missing_renderer_warnings]
          warn 'WARNING: the test never created an Inertia renderer. Maybe the code wasn\'t able to reach a `render inertia:` call? If this was intended, or you don\'t want to see this message, set ::RSpec.configuration.inertia[:skip_missing_renderer_warnings] = true'
        end
        @_inertia_render_wrapper
      end

      def expect_inertia
        expect(inertia)
      end

      def inertia_wrap_render(render)
        @_inertia_render_wrapper = InertiaRenderWrapper.new.wrap_render(render)
      end

      protected 
      
      def inertia_tests_setup?
        ::RSpec.current_example.metadata.fetch(:inertia, false)
      end
    end
  end
end

RSpec.configure do |config|
  config.include ::InertiaRails::RSpec::Helpers
  config.add_setting :inertia, default: {
    skip_missing_renderer_warnings: false
  }

  config.before(:each, inertia: true) do
    new_renderer = InertiaRails::Renderer.method(:new)
    allow(InertiaRails::Renderer).to receive(:new) do |component, controller, request, response, render, named_args|
      new_renderer.call(component, controller, request, response, inertia_wrap_render(render), **named_args)
    end
  end
end

RSpec::Matchers.define :have_exact_props do |expected_props|
  match do |inertia|
    expect(inertia.props).to eq expected_props
  end

  failure_message do |inertia|
    "expected inertia props to receive #{expected_props}, instead received #{inertia.props || 'nothing'}"
  end
end

RSpec::Matchers.define :include_props do |expected_props|
  match do |inertia|
      expect(inertia.props).to include expected_props
  end

  failure_message do |inertia|
    "expected inertia props to include #{expected_props}, instead received #{inertia.props || 'nothing'}"
  end
end

RSpec::Matchers.define :render_component do |expected_component|
  match do |inertia|
    expect(inertia.component).to eq expected_component
  end

  failure_message do |inertia|
    "expected rendered inertia component to be #{expected_component}, instead received #{inertia.component || 'nothing'}"
  end
end

RSpec::Matchers.define :have_exact_view_data do |expected_view_data|
  match do |inertia|
    expect(inertia.view_data).to eq expected_view_data    
  end

  failure_message do |inertia|
    "expected inertia view data to receive #{expected_view_data}, instead received #{inertia.view_data || 'nothing'}"
  end
end

RSpec::Matchers.define :include_view_data do |expected_view_data|
  match do |inertia|
    expect(inertia.view_data).to include expected_view_data
  end

  failure_message do |inertia|
    "expected inertia view data to include #{expected_view_data}, instead received #{inertia.view_data || 'nothing'}"
  end
end
