class InertiaShareTestController < ApplicationController
  inertia_share name: 'Brandon'
  inertia_share sport: -> { 'hockey' }
  inertia_share({a_hash: 'also works'})
  inertia_share do
    {
      position: 'center',
      number: number,
    }
  end

  def share
    render inertia: 'ShareTestComponent'
  end

  private

  def number
    29
  end
end
