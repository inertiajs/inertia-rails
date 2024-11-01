# frozen_string_literal: true
#
# Based on AbstractController::Callbacks::ActionFilter
# https://github.com/rails/rails/blob/v7.2.0/actionpack/lib/abstract_controller/callbacks.rb#L39
module InertiaRails
  class ActionFilter
    def initialize(conditional_key, actions)
      @conditional_key = conditional_key
      @actions = Array(actions).map(&:to_s).to_set
    end

    def match?(controller)
      missing_action = @actions.find { |action| !controller.available_action?(action) }
      if missing_action
        message = <<~MSG
          The #{missing_action} action could not be found for the :inertia_share
          callback on #{controller.class.name}, but it is listed in the controller's
          #{@conditional_key.inspect} option.
        MSG

        raise AbstractController::ActionNotFound.new(message, controller, missing_action)
      end

      @actions.include?(controller.action_name)
    end
  end
end
