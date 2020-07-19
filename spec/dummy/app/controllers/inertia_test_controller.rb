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
    puts "Got to location for some reason?"
    inertia_location empty_test_path
  end

  def content_type_test
    respond_to do |format|
      format.html { render inertia: 'EmptyTestComponent' }
      format.xml { render xml: [ 1, 2, 3 ] }
    end
  end
end
