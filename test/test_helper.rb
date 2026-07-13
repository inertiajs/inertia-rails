# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require 'logger'
require_relative '../spec/dummy/config/environment'
require 'rails/test_help'
require 'inertia_rails/minitest'
