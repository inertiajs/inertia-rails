if defined?(ActionDispatch::Request)
  ActionDispatch::Request.class_eval do
    def inertia?
      headers['HTTP_X_INERTIA'].present?
    end
  end
end
