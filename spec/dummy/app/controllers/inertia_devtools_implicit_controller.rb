# frozen_string_literal: true

class InertiaDevtoolsImplicitController < ApplicationController
  inertia_config default_render: true
  around_action :wrap

  def show; end

  private

  def wrap
    yield
  end
end
