# frozen_string_literal: true

# Uses the real Rails 8.2+ API when available; older Rails gets a faked accessor
# so the token-based branch is still exercised.
class InertiaLegacyTokenCsrfController < ApplicationController
  if respond_to?(:forgery_protection_verification_strategy)
    protect_from_forgery using: :header_or_legacy_token, with: :exception
  else
    def forgery_protection_verification_strategy = :header_or_legacy_token
  end

  def request_test
    head :ok
  end
end
