require_relative 'inertia_rails'

module InertiaRails::Helper
  def inertia_headers
    ::InertiaRails.html_headers.join.html_safe
  end
end
