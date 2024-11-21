module InertiaRails
  module InertiaRequest
    def inertia?
      key? 'HTTP_X_INERTIA'
    end

    def inertia_partial?
      key?('HTTP_X_INERTIA_PARTIAL_COMPONENT')
    end
  end
end

ActionDispatch::Request.include InertiaRails::InertiaRequest
