require 'inertia_rails/lazy'
require 'inertia_rails/configuration'

module InertiaRails
  CONFIGURATION = Configuration.default

  def self.configure
    yield(CONFIGURATION)
  end

  def self.configuration
    CONFIGURATION
  end

  def self.lazy(value = nil, &block)
    InertiaRails::Lazy.new(value, &block)
  end
end
