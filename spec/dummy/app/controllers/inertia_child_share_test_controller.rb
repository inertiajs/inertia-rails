class InertiaChildShareTestController < InertiaShareTestController
  inertia_share name: 'No Longer Brandon'

  def share_with_inherited
    render inertia: 'ShareTestComponent'
  end
end
