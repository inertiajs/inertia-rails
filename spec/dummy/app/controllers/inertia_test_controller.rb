class InertiaTestController < ApplicationController
  def empty_test
    render inertia: 'EmptyTestComponent'
  end

  def redirect_test
    redirect_to :empty_test
  end

  def inertia_request_test
    if request.inertia?
      head 202
    else
      head 200
    end
  end

  def inertia_partial_request_test
    if request.inertia_partial?
      head 202
    else
      head 200
    end
  end

  # Calling it my_location to avoid this in Rails 5.0
  # https://github.com/rails/rails/issues/28033
  def my_location
    inertia_location empty_test_path
  end

  def redirect_with_inertia_errors
    redirect_to empty_test_path, inertia: { errors: { uh: 'oh' } }
  end

  def error_404
    render inertia: 'ErrorComponent', status: 404
  end

  def error_500
    render inertia: 'ErrorComponent', status: 500
  end
end
