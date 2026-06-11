# frozen_string_literal: true

class InertiaConversionOptOutController < ApplicationController
  inertia_config(convert_external_redirects: false)

  def external_redirect_test
    redirect_to 'http://external-website.com/some_path', allow_other_host: true
  end
end
