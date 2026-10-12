# frozen_string_literal: true

module InertiaRails
  # Include in the controller that InertiaRails::ExceptionsApp renders error pages with.
  # Sets the response status to the error's before callbacks run, so `render` and
  # `status` use it.
  module ErrorPage
    private

    def process_action(*)
      # ActionDispatch::ShowExceptions rewrites the path to "/<status>".
      self.status = request.path_info.delete_prefix('/').to_i
      super
    end
  end
end
