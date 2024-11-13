ActionDispatch::Request.class_eval do
  def inertia?
    key? 'HTTP_X_INERTIA'
  end

  def inertia_partial?
    key?('HTTP_X_INERTIA_PARTIAL_COMPONENT')
  end
end
