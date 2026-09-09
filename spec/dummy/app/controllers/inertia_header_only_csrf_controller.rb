# frozen_string_literal: true

# Mimics Rails 8.2+ `protect_from_forgery using: :header_only`. The strategy
# accessor is defined manually so the behavior is exercised on Rails versions
# that don't ship it yet.
class InertiaHeaderOnlyCsrfController < ApplicationController
  def forgery_protection_verification_strategy = :header_only

  def request_test
    head :ok
  end
end
