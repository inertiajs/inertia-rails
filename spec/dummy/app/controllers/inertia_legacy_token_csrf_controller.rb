# frozen_string_literal: true

# Mimics Rails 8.2+ `protect_from_forgery using: :header_or_legacy_token`,
# which still falls back to authenticity tokens and needs the XSRF cookie.
class InertiaLegacyTokenCsrfController < ApplicationController
  def forgery_protection_verification_strategy = :header_or_legacy_token

  def request_test
    head :ok
  end
end
