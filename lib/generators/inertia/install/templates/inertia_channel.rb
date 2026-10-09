# frozen_string_literal: true

# Streams live props to the browser. Inertia's Action Cable transport subscribes here by default.
# see https://inertia-rails.dev/guide/live-props
class InertiaChannel < InertiaRails::LiveChannel
  # Add authorization on top of the signed stream names:
  #   def subscribed
  #     current_user ? super : reject
  #   end
end
