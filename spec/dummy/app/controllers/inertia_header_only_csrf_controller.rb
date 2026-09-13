# frozen_string_literal: true

# Uses the real Rails 8.2+ API when available; older Rails gets a faked accessor
# so the adapter's :header_only branch is still exercised.
class InertiaHeaderOnlyCsrfController < ApplicationController
  if respond_to?(:forgery_protection_verification_strategy)
    protect_from_forgery using: :header_only, with: :exception
  else
    def forgery_protection_verification_strategy = :header_only
  end

  def request_test
    head :ok
  end
end
