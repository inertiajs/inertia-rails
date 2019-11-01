class InertiaTestController < ApplicationController
  def empty_test
    render inertia: 'EmptyTestComponent'
  end

  def redirect_test
    redirect_to :empty_test
  end
end
