class InertiaTestController < ApplicationController
  def empty_test
    render inertia: 'EmptyTestComponent'
  end

  def redirect_test
    redirect_to :empty_test
  end

  def long_request_test
    sleep 1
    render inertia: 'EmptyTestComponent'
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
end
