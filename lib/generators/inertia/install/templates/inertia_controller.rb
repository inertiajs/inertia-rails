# frozen_string_literal: true

class InertiaController < ApplicationController
  inertia_share flash: -> { flash.to_hash }
end
