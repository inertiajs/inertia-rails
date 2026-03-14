# frozen_string_literal: true

require 'digest/md5'
require 'net/http'
require 'json'

require 'inertia_rails/version'
require 'inertia_rails/renderer'
require 'inertia_rails/engine'

module InertiaRails
  def self.deprecator # :nodoc:
    @deprecator ||= ActiveSupport::Deprecation.new
  end
end
