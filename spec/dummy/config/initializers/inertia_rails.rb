# frozen_string_literal: true

InertiaRails.configure do |config|
  config.always_include_errors_hash = false
  config.devtools.authorize = -> { true }
  config.devtools.base_controller = 'ApplicationController'
end
