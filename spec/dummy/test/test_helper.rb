# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'inertia_rails/minitest'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml
end
