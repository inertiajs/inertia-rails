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

  def regular_inertia_redirect_to
    inertia_redirect_to empty_test_path
  end

  def inertia_redirect_to_with_errors
    inertia_redirect_to empty_test_path, errors: 'oh bother'
  end
end
