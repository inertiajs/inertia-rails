module InertiaRails
  class StaticController < ::ApplicationController
    def static
      render inertia: params[:component]
    end
  end
end
