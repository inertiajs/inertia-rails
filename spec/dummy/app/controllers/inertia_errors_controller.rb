class InertiaErrorsController < ApplicationController
  def redirect_with_errors
    inertia_redirect_to empty_test_path, errors: { uh: 'oh' }
  end
end
