# frozen_string_literal: true

class InertiaServerHeadCustomController < ApplicationController
  inertia_config(server_head: 'custom_meta')

  def basic
    inertia_meta.add({ name: 'description', content: 'Inertia rules', head_key: 'first_head_key' })
    render inertia: 'TestComponent', props: { head: 'no conflict with a custom prop name' }
  end
end
