# frozen_string_literal: true

module InertiaRails
  # Evaluates a single prop value by dispatching on its type.
  class PropEvaluator
    def initialize(controller, **context)
      @controller = controller
      @context = context
    end

    def call(prop)
      case prop
      when BaseProp
        prop.call(@controller, **@context)
      when Proc
        @controller.instance_exec(&prop)
      else
        prop
      end
    end
  end
end
