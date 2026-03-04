# frozen_string_literal: true

module InertiaRails
  # Evaluates a single prop value by dispatching on its type.
  class PropEvaluator
    def initialize(controller)
      @controller = controller
    end

    def call(prop)
      case prop
      when BaseProp
        prop.call(@controller)
      when Proc
        @controller.instance_exec(&prop)
      else
        prop
      end
    end
  end
end
