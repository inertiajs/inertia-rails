class InertiaLambdaSharedPropsController < ApplicationController
  inertia_share someProperty: -> {
    {
      property_a: "some value",
      property_b: "this value"
    }
  }

  def lamda_shared_props
    render inertia: 'ShareTestComponent', props: { property_c: "some other value" }
  end
end
