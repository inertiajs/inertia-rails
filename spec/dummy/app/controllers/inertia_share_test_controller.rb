class InertiaShareTestController < ApplicationController
  inertia_share name: 'Brandon'
  inertia_share sport: -> { 'hockey' }
  inertia_share do
    {
      position: 'center',
      number: 29,
    }
  end
  
  def share
    render inertia: 'ShareTestComponent'
  end
end
